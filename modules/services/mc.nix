# Minecraft server (malleum.us:25565) -- Paper, vanilla gameplay.
#
# The whole server lives in this file now. The old one deferred to
# github:malleum/mc, which carried the Waverider origins plugin, MythicMobs
# spawns and a height datapack; none of that is wanted any more, so the input
# is gone and what is left is small enough to read in one sitting.
#
# Design rule: players get vanilla. No plugin here gives a player a command, an
# ability, or an item they would not have on a Mojang server. The two plugins
# that are installed both stay out of the way of that:
#
#   ViaVersion   -- lets clients on older protocol versions (1.8.9 upwards)
#                   connect. Changes nothing for anyone already on ${mcVersion}.
#   KeepInvList  -- per-player keep-inventory (see below). Registers no command
#                   and no permission; its only input is the name list here.
#
# The switches you are most likely to come back and flip are all in the block
# marked "switches" below: the two dimension gates, the whitelist, and the
# keep-inventory list. Edit, `nh os switch`, done.
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
    # do nothing at all. Paper enforces both at the server level, so there is
    # no plugin and no datapack involved, and nothing to clean up when they
    # open -- flip the flag, rebuild, and the dimension is simply there.
    #
    # Opening the Nether later does NOT regenerate anything: world_nether is
    # created the first time somebody steps through, whenever that is.
    allowNether = false;
    allowEnd = false;

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

    # Server operators: level 4, full command access.
    admins = ["malleum"];

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

    # Paper 26.3 is compiled for Java 25; jdk21 will not start it.
    jre = pkgs.jdk25_headless;

    dataDir = "/var/lib/minecraft";
    port = 25565;
    # 23 GiB on the box. Xms == Xmx is deliberate (Aikar): a heap that never
    # resizes is a heap G1 never has to grow mid-tick.
    heap = "8G";

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
      view-distance = 32;
      simulation-distance = 10;
      spawn-protection = 0;
      level-name = "42";
      level-seed = levelSeed;
      enable-command-block = false;
      # No rcon: there is no secret plumbed for it, and operators have every
      # command in-game anyway. Console output is in the journal.
      enable-rcon = false;
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

    keepInvConfig = pkgs.writeText "keepinvlist-config.yml" ''
      # Written by modules/services/mc.nix. Edits here are overwritten on every
      # server start; change the list in the Nix file instead.
      players:
      ${lib.concatMapStrings (name: "  - \"${name}\"\n") keepInventoryPlayers}
      coinflip:
      ${lib.concatMapStrings (name: "  - \"${name}\"\n") coinFlipPlayers}
      coinflip-chance: ${toString coinFlipChance}
    '';

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
  in {
    users.groups.minecraft = {};
    users.users.minecraft = {
      isSystemUser = true;
      group = "minecraft";
      home = dataDir;
      description = "Minecraft server";
    };

    networking.firewall.allowedTCPPorts = [port];

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
        install -m644 ${bukkitFile} ${dataDir}/bukkit.yml
        echo "eula=true" > ${dataDir}/eula.txt

        # Paper loads every jar it finds, so stale plugins have to go rather
        # than merely being unreferenced.
        rm -rf ${dataDir}/plugins
        install -d -m755 ${dataDir}/plugins ${dataDir}/plugins/KeepInvList
        install -m644 ${viaVersionJar} ${dataDir}/plugins/ViaVersion.jar
        install -m644 ${keepInvJar} ${dataDir}/plugins/KeepInvList.jar
        install -m644 ${keepInvConfig} ${dataDir}/plugins/KeepInvList/config.yml

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
          "-XX:+UseG1GC"
          "-XX:+ParallelRefProcEnabled"
          "-XX:MaxGCPauseMillis=200"
          "-XX:+UnlockExperimentalVMOptions"
          "-XX:+DisableExplicitGC"
          "-XX:+AlwaysPreTouch"
          "-XX:G1NewSizePercent=30"
          "-XX:G1MaxNewSizePercent=40"
          "-XX:G1HeapRegionSize=8M"
          "-XX:G1ReservePercent=20"
          "-XX:G1HeapWastePercent=5"
          "-XX:G1MixedGCCountTarget=4"
          "-XX:InitiatingHeapOccupancyPercent=15"
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
  };
}
