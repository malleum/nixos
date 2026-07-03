# Minecraft server (Paper) with the Origins-Reborn plugin (minimus).
# Players connect to malleum.us (default port 25565; the A record already
# points at this host — Minecraft is raw TCP, so nginx and the binary cache
# on 80/443 are unaffected). The BlueMap live web map is served at
# map.malleum.us — add a DNS record for it pointing at this host.
#
# Origins-Reborn is a pure server-side reimplementation of the Origins mod for
# PaperMC (https://hangar.papermc.io/cometcake575/Origins-Reborn) — players
# join with a completely vanilla client and pick their origin from a custom
# GUI; no client mods or datapacks needed. ViaVersion/ViaBackwards are also
# installed so clients newer or older than the pinned server version can join.
# The rest of the plugin set is vanilla-feel admin/QoL only (see fetch_plugin
# calls below); spark (profiler, /spark tps) is bundled with Paper itself.
#
# Declarative state (defined in this file, regenerated on every service
# start — change them HERE, not in-game/in-place):
#   server.properties, whitelist.json, ops.json
# First-run-only state (edit in place afterwards):
#   plugins/WorldGuard/config.yml (creeper/enderman grief off),
#   plugins/BlueMap/core.conf, rcon.secret
# World data, plugin jars and everything else lives in /var/lib/minecraft.
#
# Before first deploy:
# 1. Open 25565/tcp in the Oracle VCN Security List (like 80/443 for nginx).
# 2. Starting the service accepts the Minecraft EULA (https://aka.ms/MinecraftEULA).
#
# Jars are fetched once by ExecStartPre (Paper from the official fill API
# pinned to `mcVersion`; plugins from Modrinth, newest stable release for
# `mcVersion`, falling back to newest overall). To update: bump `mcVersion`
# and/or delete a jar under /var/lib/minecraft{,/plugins} and restart.
#
# Admin console goes through RCON (port 25575, not opened in the firewall):
#   mcrcon -H 127.0.0.1 -P 25575 -p "$(sudo cat /var/lib/minecraft/rcon.secret)" "<command>"
#
# Extra worlds (custom maps): rsync a world save to /var/lib/minecraft/<name>
# (chown -R minecraft:minecraft), then `mv import <name> normal` via RCON and
# `mv tp <player> <name>` / Multiverse-Portals to travel. Use FAWE (//copy,
# //schem, //paste, //rotate) to move builds between worlds. Note: the 1:1
# ISD map bundles a world-height-extender datapack advertised for 1.21.8;
# it should load on 1.21.10 (no dimension-format change between the two),
# but if that world errors on import, set mcVersion = "1.21.8" — everything
# here supports it.
{
  unify.modules.mc.nixos = {
    pkgs,
    hostConfig,
    ...
  }: let
    inherit (pkgs) lib;

    # Newest Minecraft version supported by Origins-Reborn; newer vanilla
    # clients still connect via ViaVersion. Requires Java 21.
    mcVersion = "1.21.10";
    port = 25565;
    rconPort = 25575;
    # ~half of minimus's 23G. Bigger heaps mostly just lengthen GC pauses;
    # the OS puts spare RAM to work anyway as page cache for region files.
    heap = "10G";
    dataDir = "/var/lib/minecraft";
    java = pkgs.jdk21_headless;

    # Whitelisted players and operators (level 4). UUIDs are resolved from
    # the Mojang API on the server and cached in .uuid-cache/.
    whitelistNames = ["malleum"];
    adminNames = ["malleum"];

    # Regenerated on every start; rcon.password is appended at runtime.
    serverProperties = {
      motd = "Origins SMP - pick your origin!";
      difficulty = "easy";
      view-distance = "32";
      simulation-distance = "10";
      white-list = "true";
      enforce-whitelist = "true";
      spawn-protection = "0";
      enable-rcon = "true";
      "rcon.port" = toString rconPort;
    };
    propsFile = pkgs.writeText "server.properties" (
      lib.concatLines (lib.mapAttrsToList (k: v: "${k}=${v}") serverProperties)
    );

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

      # Runs as the minecraft user in the state directory. Jar downloads are
      # fetch-once/keep-forever so restarts work offline; declarative config
      # files are rewritten on every start.
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
        fetch_plugin Chunky chunky # pregenerate chunks (run `chunky start` once)
        fetch_plugin DynamicLights dynamiclight # held torches glow (packet-only, visual)
        fetch_plugin WorldGuard worldguard # creeper/enderman grief protection (config below)
        fetch_plugin EssentialsX essentialsx # QoL commands (/spawn, /home, /tpa)
        fetch_plugin LuckPerms luckperms # permissions manager
        fetch_plugin BlueMap bluemap # live 3D web map -> map.malleum.us
        fetch_plugin Multiverse-Core multiverse-core # load custom-map worlds
        fetch_plugin Multiverse-Portals multiverse-portals # physical portals between worlds
        fetch_plugin FastAsyncWorldEdit fastasyncworldedit # admin schematic copy/paste

        # RCON password: generated once, kept out of the nix store
        if [ ! -e rcon.secret ]; then
          (
            umask 077
            head -c 512 /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 > rcon.secret
            [ -s rcon.secret ]
          )
        fi

        # server.properties: declarative, rewritten every start
        cat ${propsFile} > server.properties
        echo "rcon.password=$(cat rcon.secret)" >> server.properties

        # Whitelist + ops: declarative, rewritten every start from the name
        # lists in mc.nix. UUIDs come from the Mojang API (cached); if any
        # lookup fails the existing file is kept rather than half-written.
        resolve_uuid() {
          mkdir -p .uuid-cache
          if [ ! -s ".uuid-cache/$1" ]; then
            curl -fsSL -A "$ua" "https://api.mojang.com/users/profiles/minecraft/$1" \
              | jq -er '.id' \
              | sed -E 's/^(.{8})(.{4})(.{4})(.{4})(.{12})$/\1-\2-\3-\4-\5/' \
              > ".uuid-cache/$1"
            grep -qE '^[0-9a-f-]{36}$' ".uuid-cache/$1" || {
              rm -f ".uuid-cache/$1"
              return 1
            }
          fi
          cat ".uuid-cache/$1"
        }
        gen_players() { # $@ = names -> JSON array of {uuid, name}
          players="[]"
          for n in "$@"; do
            id=$(resolve_uuid "$n") || return 1
            players=$(echo "$players" | jq --arg u "$id" --arg n "$n" '. + [{uuid: $u, name: $n}]')
          done
          echo "$players"
        }
        if wl=$(gen_players ${toString whitelistNames}); then
          echo "$wl" > whitelist.json
        else
          echo "WARNING: uuid lookup failed; keeping existing whitelist.json"
        fi
        if ops=$(gen_players ${toString adminNames}); then
          echo "$ops" | jq 'map(. + {level: 4, bypassesPlayerLimit: true})' > ops.json
        else
          echo "WARNING: uuid lookup failed; keeping existing ops.json"
        fi

        # WorldGuard: block creeper/enderman block damage globally (mob damage
        # to players is untouched). WorldGuard expands this file with all
        # defaults on first boot, preserving these values.
        if [ ! -e plugins/WorldGuard/config.yml ]; then
          mkdir -p plugins/WorldGuard
          {
            echo "mobs:"
            echo "  block-creeper-block-damage: true"
            echo "  block-enderman-block-damage: true"
          } > plugins/WorldGuard/config.yml
        fi

        # BlueMap: pre-accept the Mojang resource download it needs to render
        if [ ! -e plugins/BlueMap/core.conf ]; then
          mkdir -p plugins/BlueMap
          echo "accept-download: true" > plugins/BlueMap/core.conf
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

    # --- BlueMap web map behind nginx (BlueMap's own webserver stays
    # firewalled on 8100; only nginx is exposed) ---
    services.nginx.virtualHosts."map.malleum.us" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8100";
        proxyWebsockets = true;
      };
    };

    # Game port only; RCON (25575) and BlueMap (8100) stay local.
    networking.firewall.allowedTCPPorts = [port];
  };
}
