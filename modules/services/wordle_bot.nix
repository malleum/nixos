{inputs, ...}: let
  matrixSecretsFile = ../secrets/matrix.yaml;
in {
  unify.modules.wordle-bot.nixos = {
    pkgs,
    config,
    ...
  }: let
    termword = inputs.termword.packages.${pkgs.stdenv.hostPlatform.system}.default;

    wordle-bot-script =
      pkgs.writers.writePython3Bin "wordle-bot" {
        libraries = [pkgs.python3Packages.matrix-nio pkgs.python3Packages.requests];
      }
      /*
      python
      */
      ''
        import asyncio
        import datetime
        import os
        import random
        import re
        import subprocess
        import sys

        from nio import (
            AsyncClient,
            MatrixRoom,
            RoomMessageText,
            Event,
            RoomMessagesResponse,
        )

        # Ensure logs are visible immediately
        sys.stdout.reconfigure(line_buffering=True)

        # Configuration
        HOMESERVER = "https://ws42.top"
        BOT_USER = "@awareness:ws42.top"
        NYT_BOT = "@nyt-games-bot:ws42.top"

        # Valid 5-letter words to use as fillers (avoiding common answers)
        FILLER_WORDS = [
            "bloke",
            "shady",
            "jumpy",
            "glint",
            "froze",
            "vivid",
            "pouch",
            "clerk",
            "mount",
            "dwarf",
            "vocal",
            "prism",
            "jumbo",
            "wreck",
            "glade",
            "crane",
            "audio",
            "raise",
            "slant",
            "point",
            "trace",
            "lions",
            "learn",
            "round",
            "price",
            "store",
            "clear",
            "bread",
            "train",
            "plate",
            "place",
            "stone",
            "phone",
            "stair",
            "least",
            "nails",
            "roast",
            "snare",
            "steal",
            "trail",
            "tread",
            "spend",
            "cloud",
            "guilt",
            "piano",
            "mouse",
            "flute",
            "grape",
            "fruit",
            "melon",
            "lemon",
            "beach",
            "coast",
            "drain",
            "track",
            "smart",
        ]

        # Square mapping: g=green, y=yellow, w=white/gray/black
        G = "🟩"
        Y = "🟨"
        W = ["⬜", "⬛", "▫️", "▪️"]


        def parse_squares(s):
            res = ""
            for char in s:
                if char == G:
                    res += "g"
                elif char == Y:
                    res += "y"
                elif char in W:
                    res += "w"
            return res


        ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


        def parse_termword_output(output):
            output = ANSI_RE.sub("", output)
            lines = [line.strip() for line in output.split("\n") if line.strip()]
            words = []
            pattern = r"([A-Z])\s+([A-Z])\s+([A-Z])\s+([A-Z])\s+([A-Z])"
            n_guesses = 0
            solved = False
            answer = None
            for line in lines:
                match = re.search(pattern, line)
                if match:
                    words.append("".join(match.groups()).lower())
                if "Solved in" in line:
                    m = re.search(r"Solved in (\d+) guesses", line)
                    if m:
                        n_guesses = int(m.group(1))
                        solved = True
                        answer = words[-1] if words else None
                    break
                if "Failed" in line:
                    n_guesses = 6
                    solved = False
                    break

            return n_guesses, solved, answer


        def get_target_words(termword_bin):
            now = datetime.datetime.now()
            # termword uses YYYY-M-D
            date_str = f"{now.year}-{now.month}-{now.day}"
            print(f"Checking termword for {date_str}...")
            try:
                output = subprocess.check_output(
                    [termword_bin, "sintfoap", "--history", date_str],
                    text=True,
                    stderr=subprocess.STDOUT,
                )
                if "No game found" in output:
                    print("No game found for sintfoap yet.")
                    return None

                n_guesses, solved, answer = parse_termword_output(output)
                if n_guesses == 0:
                    print("Could not parse guess count from output.")
                    return None

                print(
                    f"Sintfoap: {n_guesses} guesses, "
                    f"Solved: {solved}, Answer: {answer}"
                )

                # Build our sequence
                target = ["tares"]

                if solved:
                    if n_guesses == 1:
                        return [answer]  # If he got it in 1, we just guess the answer

                    # Fillers for rounds 2 to N-1
                    num_fillers = n_guesses - 2  # 1 for tares, 1 for answer
                    fillers_available = [
                        w for w in FILLER_WORDS if w != answer and w != "tares"
                    ]

                    if num_fillers > 0:
                        target += random.sample(
                            fillers_available, min(num_fillers, len(fillers_available))
                        )

                    if answer:
                        target.append(answer)
                else:
                    # He failed, so we use 6 guesses total
                    fillers_available = [w for w in FILLER_WORDS if w != "tares"]
                    target += random.sample(fillers_available, 5)

                print(f"Our plan: {target}")
                return target

            except subprocess.CalledProcessError as e:
                print(f"Error running termword: {e.output}")
                return None
            except Exception as e:
                print(f"Unexpected error: {e}")
                return None


        class WordleBot:
            def __init__(self, client, target_words):
                self.client = client
                self.target_words = target_words
                self.target_room_id = None
                self.game_finished = False

            async def find_or_create_room(self):
                await self.client.sync(timeout=3000)
                for room_id, room in self.client.rooms.items():
                    if NYT_BOT in room.users:
                        self.target_room_id = room_id
                        return room_id

                print(f"Creating new room with {NYT_BOT}...")
                resp = await self.client.room_create(is_direct=True, invite=[NYT_BOT])
                self.target_room_id = resp.room_id
                return resp.room_id

            async def message_callback(self, room: MatrixRoom, event: Event) -> None:
                if (
                    not isinstance(event, RoomMessageText)
                    or event.sender != NYT_BOT
                    or room.room_id != self.target_room_id
                ):
                    return
                body = event.body
                squares = parse_squares(body)
                if (
                    "Game over" in body
                    or "Solved" in body
                    or "ggggg" in squares
                ):
                    print("Game finished.")
                    self.game_finished = True


        async def get_today_state(client, room_id):
            """Walk room history backward; collect own guesses + game-over from today."""
            today_start = datetime.datetime.now().replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            today_start_ms = int(today_start.timestamp() * 1000)

            my_guesses = []
            game_over = False
            start = client.next_batch
            for _ in range(5):
                resp = await client.room_messages(
                    room_id, start=start, direction="b", limit=50
                )
                if not isinstance(resp, RoomMessagesResponse) or not resp.chunk:
                    break
                stop = False
                for ev in resp.chunk:
                    if ev.server_timestamp < today_start_ms:
                        stop = True
                        break
                    if not isinstance(ev, RoomMessageText):
                        continue
                    if ev.sender == BOT_USER:
                        body = ev.body.strip().lower()
                        if len(body) == 5 and body.isalpha():
                            my_guesses.append(body)
                    elif ev.sender == NYT_BOT:
                        if "Game over" in ev.body or "Solved" in ev.body:
                            game_over = True
                        if "ggggg" in parse_squares(ev.body):
                            game_over = True
                if stop:
                    break
                start = resp.end

            my_guesses.reverse()
            return my_guesses, game_over


        async def main():
            termword_bin = (
                "${termword}"
                "/bin/termword"
            )
            target_words = get_target_words(termword_bin)

            if not target_words:
                print("Nothing to do (sintfoap hasn't played or error). Exiting.")
                return

            # Wait for Synapse ready
            for i in range(30):
                try:
                    import requests

                    if (
                        requests.get(
                            f"{HOMESERVER}/_matrix/client/versions", timeout=2
                        ).status_code
                        == 200
                    ):
                        break
                except Exception:
                    pass
                print(f"Waiting for Synapse... ({i}/30)")
                await asyncio.sleep(1)

            with open(os.environ["BOT_TOKEN_FILE"], "r") as f:
                token = f.read().strip()

            client = AsyncClient(HOMESERVER, BOT_USER)
            client.access_token = token
            bot = WordleBot(client, target_words)
            client.add_event_callback(bot.message_callback, Event)

            room_id = await bot.find_or_create_room()

            my_guesses, game_over = await get_today_state(client, room_id)
            print(f"Already sent today: {my_guesses} (game_over={game_over})")

            if game_over:
                print("Today's game already finished. Exiting.")
                await client.close()
                return

            answer = target_words[-1]
            n_target = len(target_words)
            already = len(my_guesses)

            if already == 0:
                start_game = True
                to_send = list(target_words)
            elif answer in my_guesses:
                print("Answer already sent. Exiting.")
                await client.close()
                return
            elif already >= n_target:
                # Plan exhausted but answer never sent (e.g. old buggy run). Send answer.
                start_game = False
                to_send = [answer]
            else:
                # Mid-game: top up fillers (avoiding repeats) then send answer.
                start_game = False
                needed_fillers = n_target - already - 1
                sent_set = set(my_guesses) | {answer}
                pool = [w for w in FILLER_WORDS if w not in sent_set]
                new_fillers = (
                    random.sample(pool, min(needed_fillers, len(pool)))
                    if needed_fillers > 0
                    else []
                )
                to_send = new_fillers + [answer]

            print(f"Plan to send this run: {to_send}")
            sync_task = asyncio.create_task(client.sync_forever(timeout=30000))

            if start_game:
                await client.room_send(
                    room_id,
                    "m.room.message",
                    {"msgtype": "m.text", "body": "wordle"},
                )
                await asyncio.sleep(3)

            # Send guesses sequentially; NYT bot sends multiple messages per guess
            # reactive board parsing causes duplicate sends; fixed delays works
            for i, word in enumerate(to_send):
                if bot.game_finished:
                    break
                print(f"Sending guess {i + 1}: {word}")
                await client.room_send(
                    room_id,
                    "m.room.message",
                    {"msgtype": "m.text", "body": word},
                )
                await asyncio.sleep(5)

            sync_task.cancel()
            await client.close()


        if __name__ == "__main__":
            asyncio.run(main())
      '';
  in {
    # --- Sops Secret ---
    sops.secrets.matrix-wordle-hax-token = {
      sopsFile = matrixSecretsFile;
      key = "matrix_wordle_hax_token";
      owner = "matrix-synapse";
    };

    # --- Systemd Service ---
    systemd.services.matrix-wordle-bot = {
      description = "Wordle Follower Matrix Bot - Sintfoap Mimicry";
      after = ["network.target" "matrix-synapse.service"];

      serviceConfig = {
        Type = "oneshot";
        Environment = "BOT_TOKEN_FILE=${config.sops.secrets.matrix-wordle-hax-token.path}";
        ExecStart = "${wordle-bot-script}/bin/wordle-bot";

        User = "matrix-synapse";
        StateDirectory = "matrix-wordle-bot";
        PrivateTmp = true;
        ProtectSystem = "full";
        NoNewPrivileges = true;
      };
    };

    # --- Systemd Timer: Run hourly at :57 US/Eastern ---
    systemd.timers.matrix-wordle-bot = {
      description = "Timer for Daily Wordle Sintfoap Follower";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* *:57:00 US/Eastern";
        Unit = "matrix-wordle-bot.service";
      };
    };
  };
}
