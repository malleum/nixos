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
        from nio import AsyncClient, MatrixRoom, RoomMessageText

        # Configuration
        HOMESERVER = "https://ws42.top"
        BOT_USER = "@awareness:ws42.top"
        NYT_BOT = "@nyt-games-bot:ws42.top"

        SQUARES = {"🟩": "g", "🟨": "y", "⬜": "w"}


        class WordleBot:
            def __init__(self, client, wordle_hax_bin):
                self.client = client
                self.wordle_hax_bin = wordle_hax_bin
                self.process = None
                self.target_room_id = None
                self.game_solved = False

            async def start_hax(self):
                if self.process:
                    self.process.terminate()
                self.process = subprocess.Popen(
                    [self.wordle_hax_bin],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    bufsize=1
                )
                await asyncio.sleep(0.5)

            def get_next_guess(self, result_code=None):
                if not self.process:
                    return None
                if result_code:
                    self.process.stdin.write(f"{result_code}\n")
                    self.process.stdin.flush()

                while True:
                    line = self.process.stdout.readline()
                    if not line:
                        break
                    if "[AUTO-SELECTED]:" in line:
                        match = re.search(r"\[AUTO-SELECTED\]:\s*([A-Z]+)", line)
                        if match:
                            return match.group(1).lower()
                return None

            async def find_or_create_room(self):
                await self.client.sync(timeout=3000)
                for room_id, room in self.client.rooms.items():
                    if NYT_BOT in room.users:
                        self.target_room_id = room_id
                        return room_id

                print(f"Creating new room with {NYT_BOT}...")
                resp = await self.client.room_create(direct=True, invite=[NYT_BOT])
                self.target_room_id = resp.room_id
                return resp.room_id

            async def message_callback(
                self,
                room: MatrixRoom,
                event: RoomMessageText
            ) -> None:
                if event.sender != NYT_BOT or room.room_id != self.target_room_id:
                    return

                body = event.body
                is_wordle = "Wordle" in body
                has_prompt = "Guess the" in body or "attempts" in body
                has_squares = any(s in body for s in SQUARES)

                if is_wordle and (has_prompt or has_squares):
                    lines = body.strip().split("\n")
                    last_guess_line = None
                    for line in reversed(lines):
                        has_sq = any(s in line for s in SQUARES)
                        has_wd = re.search(r"[A-Z]{5}", line)
                        if has_sq and has_wd:
                            last_guess_line = line
                            break

                    if not last_guess_line:
                        if not self.process:
                            await self.start_hax()
                        guess = self.get_next_guess()
                        if guess:
                            await self.client.room_send(
                                room.room_id,
                                "m.room.message",
                                {"msgtype": "m.text", "body": guess}
                            )
                    else:
                        pattern = r"([A-Z]{5})\s+([🟩🟨⬜]{5})"
                        match = re.search(pattern, last_guess_line)
                        if match:
                            word, squares = match.groups()
                            result_code = "".join(
                                SQUARES.get(s, "w") for s in squares
                            )
                            if result_code == "ggggg":
                                print("Solved!")
                                self.game_solved = True
                            else:
                                guess = self.get_next_guess(result_code)
                                if guess:
                                    await self.client.room_send(
                                        room.room_id,
                                        "m.room.message",
                                        {"msgtype": "m.text", "body": guess}
                                    )


        async def main():
            with open(os.environ["BOT_TOKEN_FILE"], "r") as f:
                token = f.read().strip()

            client = AsyncClient(HOMESERVER, BOT_USER)
            client.access_token = token
            bot = WordleBot(client, "${wordle-hax}/bin/wordle_hax")
            client.add_event_callback(bot.message_callback, RoomMessageText)

            # Initial setup
            room_id = await bot.find_or_create_room()

            # Start a sync task in the background
            sync_task = asyncio.create_task(client.sync_forever(timeout=30000))

            # Trigger the game
            await client.room_send(
                room_id,
                "m.room.message",
                {"msgtype": "m.text", "body": "wordle"}
            )

            # Wait until solved or timeout (5 mins)
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

    # --- Systemd Timer: Run daily at 09:00 ---
    systemd.timers.matrix-wordle-bot = {
      description = "Timer for Daily Wordle Hax";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 09:00:00";
        Persistent = true;
        Unit = "matrix-wordle-bot.service";
      };
    };
  };
}
