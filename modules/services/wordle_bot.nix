{inputs, ...}: let
  matrixSecretsFile = ../secrets/matrix.yaml;
in {
  unify.modules.wordle-bot.nixos = {
    pkgs,
    config,
    ...
  }: let
    wordle-hax = inputs.wordle-hax.packages.${pkgs.system}.default;

    wordle-bot-script =
      pkgs.writers.writePython3Bin "wordle-bot" {
        libraries = [pkgs.python3Packages.matrix-nio pkgs.python3Packages.requests];
      }
      /*
      python
      */
      ''
        import asyncio
        import os
        import re
        import subprocess
        import sys

        from nio import AsyncClient, MatrixRoom, RoomMessageText

        # Ensure logs are visible immediately
        sys.stdout.reconfigure(line_buffering=True)

        # Configuration
        HOMESERVER = "https://ws42.top"
        BOT_USER = "@awareness:ws42.top"
        NYT_BOT = "@nyt-games-bot:ws42.top"

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


        class WordleBot:
            def __init__(self, client, wordle_hax_bin):
                self.client = client
                self.wordle_hax_bin = wordle_hax_bin
                self.process = None
                self.target_room_id = None
                self.game_solved = False
                self.guessed_count = 0
                self.last_guess = None

            async def start_hax(self):
                print(f"Starting hax process: {self.wordle_hax_bin}")
                if self.process:
                    self.process.terminate()
                self.process = subprocess.Popen(
                    [self.wordle_hax_bin, "--auto-select"],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    bufsize=1,
                )
                await asyncio.sleep(1)

            def get_next_guess(self, result_code=None):
                if not self.process:
                    print("Error: process not started")
                    return None

                if result_code:
                    print(f"Feeding result to hax: {result_code}")
                    self.process.stdin.write(f"{result_code}\n")
                    self.process.stdin.flush()

                print("Waiting for next guess from hax...")
                while True:
                    line = self.process.stdout.readline()
                    if not line:
                        print("Hax process closed stdout")
                        break
                    if "No candidates remaining" in line:
                        print("Solver has no candidates — state is inconsistent")
                        return None
                    if "[AUTO-SELECTED]:" in line:
                        match = re.search(
                            r"\[AUTO-SELECTED\]:\s*([A-Z]+)", line
                        )
                        if match:
                            guess = match.group(1).lower()
                            print(f"Hax recommended: {guess}")
                            return guess
                return None

            async def handle_board(self, room_id, body):
                # Extract all guesses and results from the board
                matches = re.findall(
                    r"([A-Z]{5})\s+([🟩🟨⬜⬛▫️▪️]{5})", body
                )
                if not matches:
                    if "Wordle" in body and (
                        "Guess the" in body or "attempts" in body
                    ):
                        if self.guessed_count == 0:
                            print("Game start detected. Making first guess.")
                            if not self.process:
                                await self.start_hax()
                            guess = self.get_next_guess()
                            if guess:
                                self.last_guess = guess
                                self.guessed_count = 1
                                await self.client.room_send(
                                    room_id,
                                    "m.room.message",
                                    {"msgtype": "m.text", "body": guess},
                                )
                    return

                print(
                    f"Board detected. Found {len(matches)} guesses."
                    f" We sent {self.guessed_count}."
                )

                if len(matches) >= self.guessed_count:
                    last_word, last_squares = matches[-1]
                    result_code = parse_squares(last_squares)

                    if result_code == "ggggg":
                        print(f"Wordle solved: {last_word}")
                        self.game_solved = True
                        if self.process:
                            self.process.terminate()
                        return

                    if len(matches) > self.guessed_count or (
                        len(matches) == self.guessed_count
                        and self.last_guess
                        and self.last_guess == matches[-1][0].lower()
                    ):
                        if not self.process:
                            await self.start_hax()
                            self.get_next_guess()  # consume initial auto-select
                            for i in range(len(matches) - 1):
                                self.get_next_guess(
                                    parse_squares(matches[i][1])
                                )

                        guess = self.get_next_guess(result_code)
                        if guess:
                            self.last_guess = guess
                            self.guessed_count = len(matches) + 1
                            await self.client.room_send(
                                room_id,
                                "m.room.message",
                                {"msgtype": "m.text", "body": guess},
                            )
                        else:
                            print("Solver failed — giving up")
                            self.game_solved = True

            async def find_or_create_room(self):
                await self.client.sync(timeout=3000)
                for room_id, room in self.client.rooms.items():
                    if NYT_BOT in room.users:
                        self.target_room_id = room_id
                        return room_id

                print(f"Creating new room with {NYT_BOT}...")
                resp = await self.client.room_create(
                    is_direct=True, invite=[NYT_BOT]
                )
                self.target_room_id = resp.room_id
                return resp.room_id

            async def message_callback(
                self, room: MatrixRoom, event: RoomMessageText
            ) -> None:
                if (
                    event.sender != NYT_BOT
                    or room.room_id != self.target_room_id
                ):
                    return
                await self.handle_board(room.room_id, event.body)


        async def main():
            # Wait for Synapse ready
            for i in range(30):
                try:
                    import requests

                    if (
                        requests.get(
                            f"{HOMESERVER}/_matrix/client/versions",
                            timeout=2,
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
            bot = WordleBot(
                client,
                "${wordle-hax}/bin/wordle_hax",  # noqa: E501
            )
            client.add_event_callback(bot.message_callback, RoomMessageText)

            room_id = await bot.find_or_create_room()
            sync_task = asyncio.create_task(client.sync_forever(timeout=30000))

            # Initial trigger
            await client.room_send(
                room_id,
                "m.room.message",
                {"msgtype": "m.text", "body": "wordle"},
            )

            for _ in range(60):
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
      description = "Wordle Hax Matrix Bot - Daily Play";
      after = ["network.target" "matrix-synapse.service"];

      serviceConfig = {
        Type = "oneshot";
        Environment = "BOT_TOKEN_FILE=${config.sops.secrets.matrix-wordle-hax-token.path}";
        ExecStart = "${wordle-bot-script}/bin/wordle-bot";

        # Hardening (Standard in your config)
        User = "matrix-synapse"; # Re-use synapse user for simplicity or create 'wordle-bot'
        PrivateTmp = true;
        ProtectSystem = "full";
        NoNewPrivileges = true;
      };
    };

    # --- Systemd Timer: Run daily at 6:00 AM EST (11:00 UTC) ---
    systemd.timers.matrix-wordle-bot = {
      description = "Timer for Daily Wordle Hax";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 06:00:00 US/Eastern";
        Unit = "matrix-wordle-bot.service";
      };
    };
  };
}
