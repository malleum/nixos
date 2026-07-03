# Minecraft server (Paper) with the Origins-Reborn plugin (minimus).
# Players connect to malleum.us (default port 25565; the A record already
# points at this host — Minecraft is raw TCP, so nginx and the binary cache
# on 80/443 are unaffected).
#
# Origins-Reborn is a pure server-side reimplementation of the Origins mod for
# PaperMC (https://hangar.papermc.io/cometcake575/Origins-Reborn) — players
# join with a completely vanilla client and pick their origin from a custom
# GUI; no client mods or datapacks needed. ViaVersion/ViaBackwards are also
# installed so clients newer or older than the pinned server version can join.
# The rest of the plugin set is vanilla-feel admin/QoL only (see fetch_plugin
# calls below); spark (profiler, /spark tps) is bundled with Paper itself.
#
# Before first deploy:
# 1. Open 25565/tcp in the Oracle VCN Security List (like 80/443 for nginx).
# 2. Starting the service accepts the Minecraft EULA (https://aka.ms/MinecraftEULA).
#
# Jars are fetched once by ExecStartPre into /var/lib/minecraft (Paper from the
# official fill API pinned to `mcVersion`; plugins from Modrinth, newest
# release for `mcVersion` — falling back to newest overall). To update: bump
# `mcVersion` here and/or delete the jar under /var/lib/minecraft{,/plugins}
# and restart the service.
#
# Admin console goes through RCON (port 25575, not opened in the firewall):
#   mcrcon -H 127.0.0.1 -P 25575 -p "$(sudo cat /var/lib/minecraft/rcon.secret)" "op <player>"
#
# Extra worlds (custom maps): drop a world save at /var/lib/minecraft/<name>
# (chown -R minecraft:minecraft), then `mv import <name> normal` via RCON.
# Use `mv tp`, and FAWE (//copy, //schem, //paste, //rotate) to move builds
# between worlds/dimensions.
{
  unify.modules.mc.nixos = {
    pkgs,
    hostConfig,
    ...
  }: let
    # Newest Minecraft version supported by Origins-Reborn; newer vanilla
    # clients still connect via ViaVersion. Requires Java 21.
    mcVersion = "1.21.10";
    port = 25565;
    rconPort = 25575;
    # Raise (e.g. 8G) when importing several large custom-map worlds.
    heap = "4G";
    dataDir = "/var/lib/minecraft";
    java = pkgs.jdk21_headless;

    # Aikar's flags — standard G1GC tuning for Paper servers (https://mcflags.emc.gs)
    javaFlags = builtins.concatStringsSep " " [
      "-Xms${heap}"
      "-Xmx${heap}"
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
    ];
  in {
    # --- Minecraft User & Group ---
    users.groups.minecraft = {};
    users.users.minecraft = {
      isSystemUser = true;
      group = "minecraft";
      home = dataDir;
      description = "Minecraft Server Service User";
    };

    users.users.${hostConfig.user.username}.extraGroups = ["minecraft"];

    # RCON client for server administration
    environment.systemPackages = [pkgs.mcrcon];

    # --- Systemd Service ---
    systemd.services.minecraft = {
      description = "Minecraft Server (Paper ${mcVersion} + Origins-Reborn)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.curl pkgs.jq];

      # Runs as the minecraft user in the state directory. Everything is
      # download-once/keep-forever so restarts work offline and admin edits to
      # config files are never clobbered.
      preStart = ''
        ua="malleum-nixos-minecraft (${hostConfig.user.email})"

        # Accepting the Minecraft EULA: https://aka.ms/MinecraftEULA
        echo "eula=true" > eula.txt

        # Paper: latest stable build of the pinned Minecraft version
        if [ ! -e "paper-${mcVersion}.jar" ]; then
          url=$(curl -fsSL -A "$ua" \
            "https://fill.papermc.io/v3/projects/paper/versions/${mcVersion}/builds/latest" \
            | jq -er '.downloads["server:default"].url')
          curl -fsSL -A "$ua" -o "paper-${mcVersion}.jar.part" "$url"
          mv "paper-${mcVersion}.jar.part" "paper-${mcVersion}.jar"
        fi
        ln -sfn "paper-${mcVersion}.jar" paper.jar

        # Plugins: fetched from Modrinth only if missing (delete a jar and
        # restart to update it). Newest release matching mcVersion, falling
        # back to newest overall. Failures skip the plugin instead of blocking
        # server startup — check the journal if one is missing.
        mkdir -p plugins
        loaders='loaders=["paper","purpur","bukkit","spigot"]'
        fetch_plugin() { # $1 = jar name, $2 = Modrinth project slug
          [ -e "plugins/$1.jar" ] && return 0
          api="https://api.modrinth.com/v2/project/$2/version"
          url=$(curl -fsSL -A "$ua" --get --data-urlencode "$loaders" \
            --data-urlencode 'game_versions=["${mcVersion}"]' "$api" \
            | jq -er 'first(.[] | select(.version_type == "release")).files[0].url') \
            || url=$(curl -fsSL -A "$ua" --get --data-urlencode "$loaders" "$api" \
              | jq -er '.[0].files[0].url') \
            || {
              echo "WARNING: could not resolve plugin $1 ($2); skipping"
              return 0
            }
          curl -fsSL -A "$ua" -o "plugins/$1.jar.part" "$url" || {
            echo "WARNING: download failed for plugin $1; skipping"
            rm -f "plugins/$1.jar.part"
            return 0
          }
          mv "plugins/$1.jar.part" "plugins/$1.jar"
        }
        fetch_plugin Origins-Reborn origins-reborn # server-side Origins (the point of this server)
        fetch_plugin ViaVersion viaversion # newer vanilla clients can join
        fetch_plugin ViaBackwards viabackwards # older vanilla clients can join
        fetch_plugin CoreProtect coreprotect # block logging + rollback (grief insurance)
        fetch_plugin Chunky chunky # pregenerate chunks (perf; run `chunky start` once)
        fetch_plugin DynamicLights dynamiclight # held torches glow (packet-only, visual)
        fetch_plugin Multiverse-Core multiverse-core # load custom-map worlds
        fetch_plugin FastAsyncWorldEdit fastasyncworldedit # admin schematic copy/paste

        # First-run config only; edit server.properties in place afterwards
        if [ ! -e rcon.secret ]; then
          (
            umask 077
            tr -dc A-Za-z0-9 </dev/urandom | head -c 24 > rcon.secret
          )
        fi
        if [ ! -e server.properties ]; then
          {
            echo "motd=Origins SMP - pick your origin!"
            echo "view-distance=8"
            echo "simulation-distance=6"
            echo "spawn-protection=0"
            echo "enable-rcon=true"
            echo "rcon.port=${toString rconPort}"
            echo "rcon.password=$(cat rcon.secret)"
          } > server.properties
        fi
      '';

      serviceConfig = {
        ExecStart = "${java}/bin/java ${javaFlags} -jar paper.jar nogui";
        WorkingDirectory = dataDir;
        Restart = "always";
        RestartSec = 10;
        # Paper saves worlds on SIGTERM; give it time before systemd kills it
        TimeoutStopSec = 120;
        User = "minecraft";
        Group = "minecraft";
        StateDirectory = "minecraft";
        Environment = ["HOME=${dataDir}"];

        # Hardening
        ProtectSystem = "full";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # Game port only; RCON (25575) stays local by not opening it here.
    networking.firewall.allowedTCPPorts = [port];
  };
}
