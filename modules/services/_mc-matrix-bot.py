"""The Matrix half of the Minecraft bridge.

It never touches the Minecraft server directly. Everything it knows comes from
the ServerFeed plugin's loopback HTTP API (modules/packages/mc-feed):

    GET /events?wait=25   long poll -- blocks until something happens
    GET /status           who is online and how long each has been idle

and everything it does is report those events in one Matrix room and answer a
couple of words typed in it. Configuration is entirely environment, written by
modules/services/mc.nix; the two secrets arrive as file paths so no token is
ever an argv entry or a store path.

There is no Matrix library here, for the same reason KeepInvList is sixty lines
of Java rather than two plugins: this speaks to a Synapse on 127.0.0.1, over
four endpoints of the client-server API, and matrix-nio would be a dependency
tree to spare about a hundred lines of aiohttp.

That choice does fix one thing: the bot cannot do end-to-end encryption, so the
room has to be unencrypted. It therefore *creates* the room itself rather than
waiting to be invited -- a DM started from Element would be encrypted by
default and the bot would sit in it deaf. See mc.nix for the setup notes.

The bridge is one-way as far as the game is concerned. It reads Minecraft and
writes Matrix; nothing typed in Matrix reaches the server, which is the same
rule the server itself follows -- no plugin here hands a player anything they
would not have on a Mojang server.
"""

import asyncio
import html
import json
import logging
import os
import sys
import time
from pathlib import Path
from urllib.parse import quote

import aiohttp

log = logging.getLogger("mc-matrix-bot")


def env(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, "")
    if not value:
        if default is not None:
            return default
        sys.exit(f"{name} is not set")
    return value


def secret(name: str) -> str:
    """Read a secret out of the file the unit pointed us at.

    sops-nix decrypts to /run/secrets on activation, so a missing file means
    the secret was never added rather than anything transient -- exiting is
    right, and systemd will say so.
    """
    try:
        return Path(env(name)).read_text(encoding="utf-8").strip()
    except OSError as error:
        sys.exit(f"cannot read {name}: {error}")


FEED_URL = env("MCBOT_FEED_URL").rstrip("/")
FEED_TOKEN = secret("MCBOT_FEED_TOKEN_FILE")

HOMESERVER = env("MCBOT_MATRIX_URL").rstrip("/")
MATRIX_TOKEN = secret("MCBOT_MATRIX_TOKEN_FILE")
OWNER = env("MCBOT_OWNER")
STATE = Path(env("MCBOT_STATE_DIR", "/var/lib/mcbot"))

# Long poll the plugin for this many seconds, then come back. Well under the
# client timeout below, so an empty poll is a normal 200 rather than a timeout
# to recover from.
FEED_POLL = 25
# Matrix /sync long-polls too, in milliseconds.
SYNC_TIMEOUT_MS = 30_000

API = f"{HOMESERVER}/_matrix/client/v3"

ADVANCEMENT_VERB = {
    "task": "has made the advancement",
    "goal": "has reached the goal",
    "challenge": "has completed the challenge",
}

HELP = (
    "online — everyone on the server, afk marked\n"
    "active — only the ones who are not afk\n"
    "help — this"
)


## ───────────────────────────── formatting ─────────────────────────────


def duration(seconds: int) -> str:
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    minutes, seconds = divmod(seconds, 60)
    if minutes < 60:
        return f"{minutes}m" if not seconds else f"{minutes}m{seconds}s"
    hours, minutes = divmod(minutes, 60)
    return f"{hours}h" if not minutes else f"{hours}h{minutes}m"


def render(event: dict) -> tuple[str, str] | None:
    """One line for one event, as (plain, html), or None if unrecognised.

    Unrecognised means a newer plugin talking to an older bot, which should be
    quietly ignored rather than killing the pump.
    """
    kind = event.get("type")
    player = str(event.get("player", "?"))
    safe = html.escape(player)
    text = event.get("text")

    if kind == "join":
        return f"🟢 {player} joined", f"🟢 <b>{safe}</b> joined"
    if kind == "quit":
        return f"⚪ {player} left", f"⚪ <b>{safe}</b> left"
    if kind == "death":
        # The server's own death message already names the player, and says it
        # better than anything reconstructed here would.
        body = text or f"{player} died"
        return f"💀 {body}", f"💀 {html.escape(body)}"
    if kind == "advancement":
        verb = ADVANCEMENT_VERB.get(str(event.get("kind")), ADVANCEMENT_VERB["task"])
        title = text or "?"
        return (
            f"✨ {player} {verb} [{title}]",
            f"✨ <b>{safe}</b> {verb} <b>[{html.escape(title)}]</b>",
        )
    return None


def describe(players: list[dict], afk_seconds: int) -> tuple[str, str]:
    """The body of an `online` reply: one player per line, longest idle last."""
    plain, rich = [], []
    for player in sorted(players, key=lambda p: p.get("idle", 0)):
        name = str(player.get("name", "?"))
        safe = html.escape(name)
        if player.get("afk"):
            idle = duration(player.get("idle", 0))
            plain.append(f"🌙 {name} — afk {idle}")
            rich.append(f"🌙 {safe} — <i>afk {idle}</i>")
        else:
            plain.append(f"🟢 {name}")
            rich.append(f"🟢 {safe}")

    footer = f"afk after {duration(afk_seconds)} without moving"
    return (
        "\n".join(plain) + f"\n\n({footer})",
        "<br>".join(rich) + f"<br><br><sub>{footer}</sub>",
    )


## ─────────────────────────────── the bot ───────────────────────────────


class Bot:
    def __init__(self, session: aiohttp.ClientSession) -> None:
        self.session = session
        self.room: str | None = None
        self.since: str | None = None
        self.txn = int(time.time() * 1000)

    ## state -- a room id and a sync token, so a restart neither makes a
    ## second room nor replays every command it already answered.

    def _read(self, name: str) -> str | None:
        try:
            value = (STATE / name).read_text(encoding="utf-8").strip()
            return value or None
        except OSError:
            return None

    def _write(self, name: str, value: str) -> None:
        try:
            (STATE / name).write_text(value, encoding="utf-8")
        except OSError as error:
            log.warning("cannot save %s: %s", name, error)

    ## the client-server API, four endpoints of it

    async def call(self, method: str, path: str, **kwargs) -> dict:
        """One request, retried through Synapse's rate limiter.

        M_LIMIT_EXCEEDED is the only error worth retrying: it is the server
        saying "later", with how much later in the body. Everything else is a
        bug or an expired token and should surface.
        """
        for _ in range(5):
            async with self.session.request(method, f"{API}{path}", **kwargs) as response:
                body = await response.json(content_type=None)
                if response.status == 429:
                    wait = body.get("retry_after_ms", 1000) / 1000
                    log.debug("rate limited, waiting %.1fs", wait)
                    await asyncio.sleep(wait)
                    continue
                response.raise_for_status()
                return body
        raise aiohttp.ClientError("gave up against the rate limiter")

    async def send(self, text: str, formatted: str, notice: bool = False) -> None:
        """Post one message.

        m.text for the event feed and m.notice for replies: the default push
        rules suppress notices, so this is the difference between a phone
        buzzing for a death and staying quiet for an answer that was asked for.
        """
        if self.room is None:
            return
        self.txn += 1
        try:
            await self.call(
                "PUT",
                f"/rooms/{quote(self.room)}/send/m.room.message/{self.txn}",
                json={
                    "msgtype": "m.notice" if notice else "m.text",
                    "body": text,
                    "format": "org.matrix.custom.html",
                    "formatted_body": formatted,
                },
            )
        except (aiohttp.ClientError, asyncio.TimeoutError) as error:
            # A dropped message is better than a dropped loop.
            log.warning("could not send: %s", error)

    ## startup

    async def ensure_room(self) -> None:
        """Find the room from last time, or make it.

        Unencrypted and private, with the owner invited at the same power level
        so they can rename it, set an avatar, and so on. is_direct plus the
        m.direct account data is what makes a client file it under People
        rather than as a room.
        """
        saved = self._read("room_id")
        if saved:
            try:
                await self.call("GET", f"/rooms/{quote(saved)}/state/m.room.create")
                self.room = saved
                log.info("using room %s", saved)
                return
            except aiohttp.ClientError as error:
                log.warning("saved room %s is gone (%s), making a new one", saved, error)

        created = await self.call(
            "POST",
            "/createRoom",
            json={
                "preset": "trusted_private_chat",
                "is_direct": True,
                "invite": [OWNER],
                "name": "Minecraft",
                "topic": "malleum.us — joins, deaths, advancements. Say `help`.",
                # No m.room.encryption event: this bot cannot read an encrypted
                # room, so the room must never become one.
            },
        )
        self.room = created["room_id"]
        self._write("room_id", self.room)
        log.info("created room %s and invited %s", self.room, OWNER)

        await self.mark_direct()

    async def mark_direct(self) -> None:
        """Add the room to the owner's... no: to *our* m.direct list.

        Account data is per-user, so this only files the room under People on
        the bot's side. The owner's client does the same for itself when it
        accepts an invite carrying is_direct, which is why that flag is set
        above. Failing here is cosmetic, so it must not stop the bot.
        """
        me = (await self.call("GET", "/account/whoami"))["user_id"]
        try:
            direct = await self.call("GET", f"/user/{quote(me)}/account_data/m.direct")
        except aiohttp.ClientError:
            direct = {}
        rooms = direct.get(OWNER, [])
        if self.room not in rooms:
            direct[OWNER] = rooms + [self.room]
            try:
                await self.call(
                    "PUT", f"/user/{quote(me)}/account_data/m.direct", json=direct
                )
            except aiohttp.ClientError as error:
                log.warning("could not mark the room as direct: %s", error)

    ## the two loops

    async def sync_loop(self) -> None:
        """Watch the room for commands, and accept the owner's invites.

        The first sync of a fresh state directory is taken for its position
        only: a bot that has just been deployed should not answer every
        `online` typed before it existed.
        """
        self.since = self._read("since")
        fresh = self.since is None

        # Everything this bot reads is a message in a room. Asking for only
        # that keeps a sync down to a few hundred bytes.
        sync_filter = json.dumps(
            {
                "presence": {"types": []},
                "account_data": {"types": []},
                "room": {
                    "timeline": {"limit": 20, "types": ["m.room.message"]},
                    "state": {"types": []},
                    "ephemeral": {"types": []},
                    "account_data": {"types": []},
                },
            }
        )

        while True:
            params = {"timeout": str(0 if fresh else SYNC_TIMEOUT_MS), "filter": sync_filter}
            if self.since:
                params["since"] = self.since
            try:
                body = await self.call("GET", "/sync", params=params)
            except (aiohttp.ClientError, asyncio.TimeoutError) as error:
                log.warning("sync failed: %s", error)
                await asyncio.sleep(5)
                continue

            self.since = body.get("next_batch")
            if self.since:
                self._write("since", self.since)

            if fresh:
                # Position taken; start listening from here.
                fresh = False
                continue

            for room_id in body.get("rooms", {}).get("invite", {}):
                await self.accept(room_id)

            for room_id, room in body.get("rooms", {}).get("join", {}).items():
                for event in room.get("timeline", {}).get("events", []):
                    await self.on_message(room_id, event)

    async def accept(self, room_id: str) -> None:
        """Join an invite -- but only into the room we already use.

        Anyone on the homeserver can invite this bot anywhere; joining on sight
        would let a stranger watch the server's join and death feed. The one
        case worth handling is the owner having left and been re-invited, which
        is this room and no other.
        """
        if room_id != self.room:
            log.warning("ignoring an invite to %s", room_id)
            return
        try:
            await self.call("POST", f"/rooms/{quote(room_id)}/join", json={})
            log.info("re-joined %s", room_id)
        except aiohttp.ClientError as error:
            log.warning("could not join %s: %s", room_id, error)

    async def on_message(self, room_id: str, event: dict) -> None:
        if room_id != self.room or event.get("sender") != OWNER:
            return
        content = event.get("content", {})
        if content.get("msgtype") != "m.text":
            return

        # A leading ! is allowed but not required: this is a DM, not a channel
        # where a bot has to stay out of the conversation.
        word = str(content.get("body", "")).strip().lstrip("!").lower()
        if word in ("online", "who", "list"):
            await self.reply_status(afk_only=False)
        elif word in ("active", "awake"):
            await self.reply_status(afk_only=True)
        elif word in ("help", "commands", "?"):
            await self.send(HELP, HELP.replace("\n", "<br>"), notice=True)

    async def reply_status(self, afk_only: bool) -> None:
        try:
            async with self.session.get(
                f"{FEED_URL}/status", headers={"Authorization": f"Bearer {FEED_TOKEN}"}
            ) as response:
                response.raise_for_status()
                status = await response.json(content_type=None)
        except (aiohttp.ClientError, asyncio.TimeoutError) as error:
            log.warning("status failed: %s", error)
            await self.send(
                "The server is not answering.", "The server is not answering.", notice=True
            )
            return

        players = status.get("online", [])
        if afk_only:
            players = [p for p in players if not p.get("afk")]

        if not players:
            empty = "Nobody is active." if afk_only else "Nobody is online."
            await self.send(empty, empty, notice=True)
            return

        plain, rich = describe(players, status.get("afkSeconds", 300))
        header = f"{len(players)} {'active' if afk_only else 'online'}"
        await self.send(
            f"{header}\n{plain}", f"<b>{header}</b><br>{rich}", notice=True
        )

    async def feed_loop(self) -> None:
        """Forward server events until the process dies.

        Every failure here is the Minecraft server being down or restarting,
        which is routine -- back off and keep polling rather than exiting and
        dragging the Matrix connection down with it.

        A poll returns everything that happened while it was waiting, and that
        whole batch goes out as one message: four people dying to the same
        creeper should be one notification, not four.
        """
        while True:
            try:
                async with self.session.get(
                    f"{FEED_URL}/events?wait={FEED_POLL}",
                    headers={"Authorization": f"Bearer {FEED_TOKEN}"},
                ) as response:
                    response.raise_for_status()
                    payload = await response.json(content_type=None)
            except (aiohttp.ClientError, asyncio.TimeoutError) as error:
                log.warning("event poll failed: %s", error)
                await asyncio.sleep(5)
                continue

            lines = [rendered for e in payload.get("events", []) if (rendered := render(e))]
            if lines:
                await self.send(
                    "\n".join(plain for plain, _ in lines),
                    "<br>".join(rich for _, rich in lines),
                )


async def main() -> None:
    STATE.mkdir(parents=True, exist_ok=True)

    async with aiohttp.ClientSession(
        headers={"Authorization": f"Bearer {MATRIX_TOKEN}"},
        # Long enough for a /sync that waits SYNC_TIMEOUT_MS and a feed poll
        # that waits FEED_POLL, with room for the homeserver to be slow.
        timeout=aiohttp.ClientTimeout(total=SYNC_TIMEOUT_MS / 1000 + 30),
    ) as session:
        bot = Bot(session)

        who = await bot.call("GET", "/account/whoami")
        log.info("logged in as %s, owner is %s", who["user_id"], OWNER)

        await bot.ensure_room()
        await asyncio.gather(bot.sync_loop(), bot.feed_loop())


logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
asyncio.run(main())
