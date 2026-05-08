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

        from nio import AsyncClient, MatrixRoom, RoomMessageText, Event

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


        def parse_termword_output(output):
            lines = [line.strip() for line in output.split("\n") if line.strip()]
            words = []
            pattern = r"([A-Z])\s+([A-Z])\s+([A-Z])\s+([A-Z])\s+([A-Z])"
            for line in lines:
                match = re.search(pattern, line)
                if match:
                    words.append("".join(match.groups()).lower())

            n_guesses = 0
            solved = False
            for line in reversed(lines):
                if "Solved in" in line:
                    m = re.search(r"Solved in (\d+) guesses", line)
                    if m:
                        n_guesses = int(m.group(1))
                        solved = True
                        break
                if "Failed" in line:
                    n_guesses = 6
                    solved = False
                    break

            answer = words[-1] if solved and words else None
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
                self.game_solved = False
                self.guessed_count = 0

            async def handle_board(self, room_id, body):
                if self.game_solved:
                    return

                # Check if it's already solved or failed
                squares = parse_squares(body)
                if "Solved" in body or "Failed" in body or "ggggg" in squares:
                    print("Game already finished in this room.")
                    self.game_solved = True
                    return

                # Extract guesses already on the board
                matches = re.findall(r"([A-Z]{5})\s+([🟩🟨⬜⬛▫️▪️]{5})", body)

                # Update current count
                self.guessed_count = len(matches)
                print(f"Current board has {self.guessed_count} guesses.")

                if self.guessed_count < len(self.target_words):
                    next_word = self.target_words[self.guessed_count]
                    print(f"Sending guess {self.guessed_count + 1}: {next_word}")
                    await self.client.room_send(
                        room_id,
                        "m.room.message",
                        {"msgtype": "m.text", "body": next_word},
                    )
                else:
                    print("Matched the target number of guesses.")
                    self.game_solved = True

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
                await self.handle_board(room.room_id, event.body)


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
            sync_task = asyncio.create_task(client.sync_forever(timeout=30000))

            # Trigger bot to show current state
            await client.room_send(
                room_id,
                "m.room.message",
                {"msgtype": "m.text", "body": "wordle"},
            )

            # Wait for completion or timeout
            for _ in range(120):  # Longer timeout for multiple guesses
                if bot.game_solved:
                    break
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
