# Minecraft server (malleum.us:25565) -- Paper, vanilla gameplay.
#
# The whole server lives in this file now. The old one deferred to
# github:malleum/mc, which carried the Waverider origins plugin, MythicMobs
# spawns and a height datapack; none of that is wanted any more, so the input
# is gone and what is left is small enough to read in one sitting.
#
# Design rule: players get vanilla. No plugin here gives a player a command, an
# ability, or an item they would not have on a Mojang server. The three plugins
# that are installed all stay out of the way of that:
#
#   ViaVersion   -- lets clients on older protocol versions (1.8.9 upwards)
#                   connect. Changes nothing for anyone already on ${mcVersion}.
#   KeepInvList  -- per-player keep-inventory (see below). Registers no command
#                   and no permission; its only input is the name list here.
#   ServerFeed   -- reports joins, leaves, deaths and advancements on a loopback
#                   HTTP API, and answers "who is online, who is afk". Nothing
#                   it does is visible in game, and nothing said on Matrix
#                   reaches the server; the mcbot unit below is the half that
#                   actually talks to Matrix.
#
# Paper has bundled Luck's spark profiler since 1.21, so `/spark` is already
# there with no jar to install. It is op-gated and invisible to everyone else;
# it is the right first move before changing any number in this file, because
# it says which of them actually costs anything.
#
# The switches you are most likely to come back and flip are all in the block
# marked "switches" below: the two dimension gates, the whitelist, the
# keep-inventory list and the Matrix bot. Edit, `nh os switch`, done.
{inputs, ...}: {
  unify.modules.mc.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    ## ─────────────────────────── switches ───────────────────────────

    # Nether and End are shut for progression reasons: portals light, and then
    # do nothing at all. No plugin and no datapack is involved, and there is
    # nothing to clean up when they open -- flip the flag, rebuild, and the
    # dimension is simply there.
    #
    # The two flags reach the server by different routes, because the server
    # honours different keys for them:
    #
    #   * End  -- bukkit.yml `settings.allow-end`, which Bukkit reads.
    #   * Nether -- paper-global.yml `misc.enable-nether`, which Paper reads.
    #     `allow-nether` in server.properties is VANILLA's key and Paper
    #     ignores it outright, so setting that alone leaves the Nether open.
    #     It is still written, for a reader who greps server.properties.
    #
    # Opening the Nether later does NOT regenerate anything: the dimension is
    # created the first time somebody steps through, whenever that is.
    allowNether = false;
    allowEnd = false;

    # RCON: the admin console, on loopback only. The port is deliberately NOT
    # in allowedTCPPorts, so the only way in is from the box itself. The
    # password is generated on the box at first start and never enters this
    # repo or the nix store -- see rconPasswordScript.
    #
    # RCON is a level-4 console with no account behind it: whoever can reach
    # the port can run any command. That it is unreachable from outside is the
    # whole of its security, hence the firewall note above.
    rconPort = 25575;

    # The world seed. Empty means "generate a random one on first start", and
    # that random seed is then recorded in world/level.dat -- so this only has
    # any effect on a world that does not exist yet. Setting it after the world
    # has generated changes nothing; the world would have to be deleted first.
    levelSeed = "";

    # Only these names can connect (enforce-whitelist makes the server kick
    # anyone removed from the list, not just refuse new logins).
    whitelist = [
      "malleum"
      "opcornpay"
      "jaderabbit__"
      "sintfoap"
      "marvin1984"
      "tczcatlipoca"
      "siocledesea"
      "emyfun14"
    ];

    # Server operators: level 4, full command access. Deliberately empty --
    # nobody has commands in-game, and administration goes through the RCON
    # console instead (see rconPort below). A name here would hand that
    # account every command from a survival session, which is the thing this
    # server is trying not to have.
    admins = [];

    # The keep-inventory list. These players keep their items and XP on death;
    # everybody else drops both exactly like vanilla. Names must match the
    # account name, case does not matter.
    #
    # This is the one thing that cannot be done with configuration: the
    # keepInventory gamerule is a single boolean for the whole world. The
    # KeepInvList plugin (modules/packages/mc-keepinv) exists purely to make it
    # per-player, and does nothing else.
    keepInventoryPlayers = [
      "tczcatlipoca"
      "siocledesea"
      "emyfun14"
    ];

    # Half-measure: these players keep their items and XP on a coin flip, rolled
    # fresh on every death, at coinFlipChance. A name in both lists is simply an
    # always-keeper -- the roll never happens for it.
    #
    # Nobody is told which way the roll went: a loss looks exactly like an
    # ordinary vanilla death. The server logs every roll, so there is a record
    # in the journal when somebody swears it cheated them.
    coinFlipPlayers = [
      "sintfoap"
    ];
    coinFlipChance = 0.5;

    # The Matrix bot: a private, unencrypted room with one person in it, which
    # reports every join, leave, death and advancement, and answers `online`
    # and `active`. Set to null to remove the bot, the ServerFeed plugin and
    # the secrets in one go.
    #
    # It talks to the Synapse in modules/services/matrix.nix over loopback, as
    # its own account on that homeserver. Setup is three commands and is
    # written out above the mcbot unit further down.
    matrixBot = {
      # Who the bot opens the room with, and the only person it takes commands
      # from. A full MXID.
      owner = "@malleum:ws42.top";
      # The local Synapse listener (matrix.nix: 127.0.0.1:8008).
      homeserver = "http://127.0.0.1:8008";
      # A player who has not moved, looked around, hit anything, typed, or run
      # a command for this long is afk. `active` hides them; `online` marks
      # them and says for how long.
      afkSeconds = 300;
      # Loopback only: ServerFeed binds 127.0.0.1 and the bot connects to it.
      feedPort = 8765;
    };

    ## ──────────────────────── the rest of it ────────────────────────

    mcVersion = "26.3";
    paperBuild = "34";

    # Paper 26.3 has no stable channel yet -- build 34 is ALPHA, which is the
    # price of running the newest Minecraft release the week it lands. To move
    # to a newer build: take the url and sha256 from
    #   curl -s https://fill.papermc.io/v3/projects/paper/versions/26.3/builds \
    #     | jq '.[0].downloads."server:default"'
    paperJar = pkgs.fetchurl {
      url = "https://fill-data.papermc.io/v1/objects/6806a684171477d63bd3fbcbfcd5f862114cc350b00076dea796cb584b984323/paper-${mcVersion}-${paperBuild}.jar";
      hash = "sha256-aAamhBcUd9Y70/vL/NX4YhFMw1CwAHbep5bLWEuYQyM=";
    };

    # Older clients joining a newer server. Nothing else in the Via family is
    # installed: ViaBackwards and ViaRewind solve the opposite problem (new
    # clients on old servers), which this server does not have.
    viaVersionJar = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P1OZGk5p/versions/TEgYlalY/ViaVersion-5.12.1-SNAPSHOT.jar";
      hash = "sha256-072ZwsSSNn45o+CXYdlbkR96kEr0/QjvyXVIyYeDD8s=";
    };

    keepInvJar = inputs.self.packages.${system}.mc-keepinv;
    feedJar = inputs.self.packages.${system}.mc-feed;

    botEnabled = matrixBot != null;

    # sops-nix decrypts to /run/secrets; these two paths are what the two
    # halves of the bridge are handed.
    matrixTokenPath = config.sops.secrets.mcbot_matrix_token.path;
    feedTokenPath = config.sops.secrets.mcbot_feed_token.path;

    # Paper 26.3 is compiled for Java 25; jdk21 will not start it.
    jre = pkgs.jdk25_headless;

    dataDir = "/var/lib/minecraft";
    port = 25565;
    # 23 GiB on the box. Xms == Xmx is deliberate (Aikar): a heap that never
    # resizes is a heap G1 never has to grow mid-tick.
    #
    # If this crosses the 12G line in either direction the four G1 sizing flags
    # in ExecStart have to move with it -- Aikar publishes a different set
    # above and below it. See the comment there.
    heap = "12G";

    serverProperties = {
      server-port = port;
      motd = "la senco de la vivo, de la universo kaj de ĉio";
      difficulty = "hard";
      hardcore = false;
      gamemode = "survival";
      force-gamemode = false;
      pvp = true;
      online-mode = true;
      white-list = true;
      enforce-whitelist = true;
      allow-nether = allowNether;
      max-players = 20;
      # Paper's send distance, not its tick distance -- simulation-distance
      # below is what actually ticks. Still not free: every chunk in here is
      # generated, lit, kept in the heap and pushed over the wire. 32 meant a
      # ~4200-chunk frontier per player, which is where the generation stalls
      # came from. 20 is still well past what a default client (12) renders,
      # and chunk-loading-advanced.auto-config-send-distance means a client
      # asking for less is sent less.
      view-distance = 20;
      simulation-distance = 10;
      spawn-protection = 0;
      level-name = "42";
      level-seed = levelSeed;
      enable-command-block = false;
      # The console. `rcon.password` is a placeholder: rconPasswordScript
      # overwrites this line on the box at every start with the generated
      # password, so the value here never has to be a secret. RCON binds
      # whatever `server-ip` is (empty, so every interface) -- the firewall is
      # what keeps it local, not this file.
      enable-rcon = true;
      "rcon.port" = rconPort;
      "rcon.password" = "PLACEHOLDER";
      # An RCON command is administration, not chat; there is nobody opped to
      # broadcast it to anyway.
      broadcast-rcon-to-ops = false;
      enable-status = true;
      sync-chunk-writes = false; # Paper recommends off on Linux; big TPS win
    };

    propertiesFile = pkgs.writeText "server.properties" (
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value: "${name}=${
            if builtins.isBool value
            then lib.boolToString value
            else toString value
          }"
        )
        serverProperties
      )
      + "\n"
    );

    # allow-end has no server.properties key; it is Bukkit's, and this is the
    # only reason this file is managed at all. Everything omitted here keeps
    # Paper's default.
    bukkitFile = pkgs.writeText "bukkit.yml" ''
      settings:
        allow-end: ${lib.boolToString allowEnd}
    '';

    ## ───────────────────── paper's own two configs ──────────────────
    #
    # config/paper-global.yml and config/paper-world-defaults.yml are where
    # every real Paper performance knob lives. They are handled differently
    # from bukkit.yml above: Paper stamps both with a `_version` key and runs
    # its own key-renaming migrations against it on an upgrade, so replacing
    # them wholesale would throw that away. Instead the overlays below are
    # merged onto whatever is on disk at every start (paperConfigScript).
    #
    # So: a key named here is forced back to the value here on every boot and a
    # hand-edit to it never survives, exactly like the rest of this file.
    # Anything not named here keeps Paper's default. On a fresh data directory
    # the overlay just becomes the file and Paper fills in the rest.
    #
    # Nothing here changes a mechanic. Everything that would -- entity
    # activation ranges, despawn ranges, item merge radius, alternative item
    # despawn rates -- is deliberately left alone, because a player is supposed
    # to be unable to tell this is not a Mojang server.

    paperGlobalOverlay = pkgs.writeText "paper-global-overlay.yml" ''
      misc:
        # THE Nether switch. server.properties `allow-nether` is vanilla's key
        # and Paper ignores it, so this is the one that decides. Named here so
        # Paper's default (true) cannot drift back in on an upgrade.
        enable-nether: ${lib.boolToString allowNether}
      chunk-loading-advanced:
        # Send a client only as many chunks as it actually asked for, rather
        # than view-distance to everyone. A player rendering at 12 costs 12.
        auto-config-send-distance: true
      chunk-loading-basic:
        # Sending a chunk is network and disk, not tick time, and the join at
        # a 20-chunk radius is ~1700 chunks. The default 75/s makes that a
        # twenty-second trickle. Generation and load rates are left at Paper's
        # defaults on purpose -- those gate real work.
        player-max-chunk-send-rate: 150.0
    '';

    paperWorldDefaultsOverlay = pkgs.writeText "paper-world-defaults-overlay.yml" ''
      anticheat:
        anti-xray:
          # Off, and named here so it stays off. It is pure CPU and it hides
          # nothing from a whitelisted server of eight people.
          enabled: false
      chunks:
        # Default 24. Lower means the autosave sweep is spread over more ticks
        # instead of landing as a spike.
        max-auto-save-chunks-per-tick: 8
        # Paper DELETES entities past these limits when a chunk saves, so the
        # numbers are set where ordinary play cannot reach them and only a
        # genuinely pathological chunk gets clipped. `item` is deliberately
        # absent: capping it would eat players' dropped items.
        entity-per-chunk-save-limit:
          experience_orb: 256
          arrow: 128
          spectral_arrow: 128
          snowball: 64
          ender_pearl: 64
      misc:
        # Behaviour-identical to vanilla for everything short of deliberately
        # exotic update-order circuits, and an order of magnitude cheaper on
        # large redstone. The single biggest free win in this file.
        redstone-implementation: ALTERNATE_CURRENT
      tick-rates:
        behavior:
          villager:
            # Default -1 (every tick). Villager brains are the top CPU cost on
            # any server that grows a trading hall. Re-validating a claimed
            # workstation three times a second instead of twenty is not
            # something a player can observe.
            validatenearbypoi: 60
        sensor:
          villager:
            # Default 40. Doubling it means a villager notices a new bell or
            # meeting point in four seconds rather than two.
            secondarypoisensor: 80
    '';

    # yq merges right-over-left, so the overlay wins on the keys it names and
    # Paper keeps `_version` and every other key it wrote.
    paperConfigScript = pkgs.writeShellScript "minecraft-paper-config" ''
      set -eu
      PATH=${lib.makeBinPath (with pkgs; [yq-go coreutils])}

      install -d -m755 ${dataDir}/config

      merge() {
        if [ -s "$2" ]; then
          yq ea -i '. as $x ireduce ({}; . * $x)' "$2" "$1"
        else
          install -m644 "$1" "$2"
        fi
      }

      merge ${paperGlobalOverlay} ${dataDir}/config/paper-global.yml
      merge ${paperWorldDefaultsOverlay} ${dataDir}/config/paper-world-defaults.yml
    '';

    # The RCON password lives on the box and nowhere else: generated once, on
    # the first start that finds no password file, and reused afterwards so a
    # rebuild does not invalidate a session. server.properties has to carry it
    # in the clear, so that file drops to 0640 minecraft:minecraft here -- it
    # is installed 0644 by preStart and narrowed immediately below.
    #
    # Rotating it is `rm .rcon-password` plus a restart.
    rconPasswordScript = pkgs.writeShellScript "minecraft-rcon-password" ''
      set -eu
      PATH=${lib.makeBinPath (with pkgs; [coreutils gnused])}

      file=${dataDir}/.rcon-password
      if [ ! -s "$file" ]; then
        # head closing the pipe makes tr report EPIPE; the password is already
        # written by then, so the message is noise and only the exit status of
        # head (0) reaches set -e.
        (umask 077
          LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null \
            | head -c 40 > "$file")
        echo "minecraft: generated a new RCON password in $file" >&2
      fi
      chmod 600 "$file"

      # Alphanumeric by construction, so nothing here needs escaping.
      sed -i "s|^rcon.password=.*|rcon.password=$(cat "$file")|" \
        ${dataDir}/server.properties
      chmod 640 ${dataDir}/server.properties
    '';

    # `sudo mc-console` for a prompt, `sudo mc-console <command>` for one
    # command. It needs root (or the minecraft user) only to read the password
    # file; the connection itself is loopback.
    mcConsole = pkgs.writeShellScriptBin "mc-console" ''
      set -eu
      file=${dataDir}/.rcon-password
      if [ ! -r "$file" ]; then
        echo "mc-console: cannot read $file -- run this as root" >&2
        exit 1
      fi
      pw=$(cat "$file")
      # -t is mcrcon's interactive terminal mode. With arguments, each one is
      # sent as a whole command, so a command with spaces has to stay quoted.
      if [ $# -eq 0 ]; then
        exec ${pkgs.mcrcon}/bin/mcrcon -H 127.0.0.1 -P ${toString rconPort} -p "$pw" -t
      else
        exec ${pkgs.mcrcon}/bin/mcrcon -H 127.0.0.1 -P ${toString rconPort} -p "$pw" "$@"
      fi
    '';

    keepInvConfig = pkgs.writeText "keepinvlist-config.yml" ''
      # Written by modules/services/mc.nix. Edits here are overwritten on every
      # server start; change the list in the Nix file instead.
      players:
      ${lib.concatMapStrings (name: "  - \"${name}\"\n") keepInventoryPlayers}
      coinflip:
      ${lib.concatMapStrings (name: "  - \"${name}\"\n") coinFlipPlayers}
      coinflip-chance: ${toString coinFlipChance}
    '';

    feedConfig = pkgs.writeText "serverfeed-config.yml" ''
      # Written by modules/services/mc.nix. Edits here are overwritten on every
      # server start; change the matrixBot block in the Nix file instead.
      listen-port: ${toString matrixBot.feedPort}
      afk-seconds: ${toString matrixBot.afkSeconds}
      token-file: "${feedTokenPath}"
    '';

    # Its own process rather than more Java in the server: it holds the
    # homeserver connection, the access token and every Python dependency that
    # comes with them, and reaches the server only through ServerFeed's
    # loopback API. aiohttp is the whole dependency list -- see the module
    # docstring in _mc-matrix-bot.py for why there is no matrix-nio.
    botPython = pkgs.python3.withPackages (ps: [ps.aiohttp]);

    # whitelist.json and ops.json are keyed by UUID, which only Mojang can hand
    # out, so the names above are resolved at startup and cached. A name that
    # cannot be resolved (typo, or Mojang unreachable on a cold cache) is left
    # out with a warning rather than taking the server down with it.
    accountsScript = pkgs.writeShellScript "minecraft-accounts" ''
      set -u
      PATH=${lib.makeBinPath (with pkgs; [curl jq coreutils gnused])}

      cache=${dataDir}/.uuid-cache
      mkdir -p "$cache"

      uuid_of() {
        local name=$1 id
        if [ -s "$cache/$name" ]; then
          cat "$cache/$name"
          return 0
        fi
        id=$(curl -sf --max-time 10 \
          "https://api.mojang.com/users/profiles/minecraft/$name" \
          | jq -r '.id // empty')
        if [ -z "$id" ]; then
          echo "minecraft: could not resolve '$name' to a UUID, leaving it out" >&2
          return 1
        fi
        # Mojang returns the id undashed; both files want it dashed.
        id=$(echo "$id" | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/')
        printf '%s' "$id" > "$cache/$name"
        printf '%s' "$id"
      }

      entries() {
        local first=1 name id extra=$1
        shift
        printf '['
        for name in "$@"; do
          id=$(uuid_of "$name") || continue
          [ $first -eq 1 ] || printf ','
          first=0
          printf '{"uuid":"%s","name":"%s"%s}' "$id" "$name" "$extra"
        done
        printf ']\n'
      }

      entries "" ${lib.escapeShellArgs whitelist} > ${dataDir}/whitelist.json
      entries ',"level":4,"bypassesPlayerLimit":false' ${lib.escapeShellArgs admins} \
        > ${dataDir}/ops.json
    '';
  in
    lib.mkMerge [
      ## ───────────────────────── the matrix bot ───────────────────────
      #
      # First-time setup, once, before the first rebuild:
      #
      #   1. Make the account. Registration on this homeserver needs a token
      #      (matrix.nix: registration_requires_token), so mint one and
      #      register through it, or register from Element while logged in as
      #      an admin. Any password will do; it is used once, in step 2.
      #
      #   2. Trade the password for an access token -- the bot logs in with the
      #      token and never sees the password:
      #
      #        curl -s http://127.0.0.1:8008/_matrix/client/v3/login \
      #          -H 'Content-Type: application/json' -d '{
      #            "type": "m.login.password",
      #            "identifier": {"type": "m.id.user", "user": "mcbot"},
      #            "password": "the password from step 1",
      #            "initial_device_display_name": "mcbot"
      #          }' | jq -r .access_token
      #
      #   3. Secrets:
      #        cat > modules/secrets/mcbot.yaml <<EOF
      #        matrix_token: the token from step 2
      #        feed_token: $(head -c 32 /dev/urandom | base64)
      #        EOF
      #        sops -e -i modules/secrets/mcbot.yaml
      #
      #   4. nh os switch
      #
      # The bot then creates the room and invites ${matrixBot.owner}; accept
      # it. Do NOT start the DM from Element instead -- Element encrypts DMs by
      # default and this bot has no end-to-end encryption, so it would be sat
      # in a room it cannot read. If that happens, leave the room, delete
      # /var/lib/mcbot/room_id and restart mcbot.
      (lib.mkIf botEnabled {
        # The feed token is read by the server JVM (as the minecraft user) and
        # by the bot, so it is group-readable; the Matrix token is the bot's
        # alone.
        sops.secrets.mcbot_feed_token = {
          sopsFile = ../secrets/mcbot.yaml;
          key = "feed_token";
          owner = "minecraft";
          group = "mcbot";
          mode = "0440";
        };
        sops.secrets.mcbot_matrix_token = {
          sopsFile = ../secrets/mcbot.yaml;
          key = "matrix_token";
          owner = "mcbot";
          mode = "0400";
        };

        users.groups.mcbot = {};
        users.users.mcbot = {
          isSystemUser = true;
          group = "mcbot";
          description = "Minecraft Matrix bot";
        };

        systemd.services.mcbot = {
          description = "Matrix bot for the Minecraft server";
          wantedBy = ["multi-user.target"];
          # Neither dependency is a `requires`: the bot survives both of them
          # being down (it retries), and taking the bot out for a Minecraft
          # restart would be exactly the wrong way round.
          after = ["network-online.target" "matrix-synapse.service" "minecraft.service"];
          wants = ["network-online.target"];

          environment = {
            MCBOT_FEED_URL = "http://127.0.0.1:${toString matrixBot.feedPort}";
            MCBOT_FEED_TOKEN_FILE = feedTokenPath;
            MCBOT_MATRIX_URL = matrixBot.homeserver;
            MCBOT_MATRIX_TOKEN_FILE = matrixTokenPath;
            MCBOT_OWNER = matrixBot.owner;
            MCBOT_STATE_DIR = "/var/lib/mcbot";
            PYTHONUNBUFFERED = "1";
          };

          serviceConfig = {
            User = "mcbot";
            Group = "mcbot";
            # The room id and the sync token live here: without them a restart
            # would make a second room and re-answer old commands.
            StateDirectory = "mcbot";
            ExecStart = "${botPython}/bin/python ${./_mc-matrix-bot.py}";
            Restart = "always";
            RestartSec = 15;

            # It needs loopback, two secret files and its state directory.
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            RestrictSUIDSGID = true;
            RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
            SystemCallFilter = ["@system-service"];
            MemoryDenyWriteExecute = true;
          };
        };
      })

      {
        users.groups.minecraft = {};
        users.users.minecraft = {
          isSystemUser = true;
          group = "minecraft";
          home = dataDir;
          description = "Minecraft server";
        };

        # Note what is NOT here: rconPort. The console is reachable from the
        # box and from nowhere else.
        networking.firewall.allowedTCPPorts = [port];

        environment.systemPackages = [mcConsole];

        systemd.services.minecraft = {
          description = "Minecraft server (Paper ${mcVersion} build ${paperBuild})";
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target"];
          after = ["network-online.target"];

          # Everything the server reads that this repo owns is rewritten here, so a
          # rebuild is the only way to change the server and a hand-edit on the box
          # never survives. The world, player data and plugin state are untouched.
          preStart = ''
            install -m644 ${propertiesFile} ${dataDir}/server.properties
            ${rconPasswordScript}
            install -m644 ${bukkitFile} ${dataDir}/bukkit.yml
            echo "eula=true" > ${dataDir}/eula.txt
            ${paperConfigScript}

            # Paper loads every jar it finds, so a plugin dropped from this file
            # has to be deleted rather than merely left unreferenced. Only the
            # jars though: Paper never loads anything out of a plugin's data
            # directory, so wiping those buys no safety and would throw away
            # on-disk state (a pregeneration task, say) that is not ours.
            rm -f ${dataDir}/plugins/*.jar
            install -d -m755 ${dataDir}/plugins ${dataDir}/plugins/KeepInvList
            install -m644 ${viaVersionJar} ${dataDir}/plugins/ViaVersion.jar
            install -m644 ${keepInvJar} ${dataDir}/plugins/KeepInvList.jar
            install -m644 ${keepInvConfig} ${dataDir}/plugins/KeepInvList/config.yml
            ${lib.optionalString botEnabled ''
              install -d -m755 ${dataDir}/plugins/ServerFeed
              install -m644 ${feedJar} ${dataDir}/plugins/ServerFeed.jar
              install -m644 ${feedConfig} ${dataDir}/plugins/ServerFeed/config.yml
            ''}

            ${accountsScript}
          '';

          serviceConfig = {
            User = "minecraft";
            Group = "minecraft";
            StateDirectory = "minecraft";
            WorkingDirectory = dataDir;
            Restart = "always";
            RestartSec = 10;
            # 143 is SIGTERM; Paper exits with it on a clean stop.
            SuccessExitStatus = "0 143";
            # Paper flushes chunks on shutdown and that is not instant.
            TimeoutStopSec = 120;

            ExecStart = lib.concatStringsSep " " [
              "${jre}/bin/java"
              "-Xms${heap}"
              "-Xmx${heap}"
              # Aikar's flags, the standard G1 tuning for a Minecraft heap.
              # The four sizing flags below are the >=12G variant; at a heap
              # under 12G they go back to 30 / 40 / 8M / 15.
              "-XX:+UseG1GC"
              "-XX:+ParallelRefProcEnabled"
              "-XX:MaxGCPauseMillis=200"
              "-XX:+UnlockExperimentalVMOptions"
              "-XX:+DisableExplicitGC"
              "-XX:+AlwaysPreTouch"
              "-XX:G1NewSizePercent=40"
              "-XX:G1MaxNewSizePercent=50"
              "-XX:G1HeapRegionSize=16M"
              "-XX:G1ReservePercent=20"
              "-XX:G1HeapWastePercent=5"
              "-XX:G1MixedGCCountTarget=4"
              "-XX:InitiatingHeapOccupancyPercent=20"
              "-XX:G1MixedGCLiveThresholdPercent=90"
              "-XX:G1RSetUpdatingPauseTimePercent=5"
              "-XX:SurvivorRatio=32"
              "-XX:+PerfDisableSharedMem"
              "-XX:MaxTenuringThreshold=1"
              "-Dusing.aikars.flags=https://mcflags.emc.gs"
              "-Daikars.new.flags=true"
              "-jar ${paperJar}"
              "--nogui"
            ];

            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            RestrictSUIDSGID = true;
          };
        };
      }
    ];
}
