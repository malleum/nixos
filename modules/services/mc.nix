# Minecraft server (Paper) with Origins-Reborn and a Star Wars world collection.
# Players connect to malleum.us:25565 (raw TCP; nginx and the binary cache on
# 80/443 are unaffected). BlueMap is served at map.malleum.us.
#
# --- Origins ---
# Origins-Reborn is a pure server-side reimplementation of the Origins mod for
# PaperMC — players join with a stock vanilla client and pick their origin via
# a custom GUI. ViaVersion/ViaBackwards let clients on any nearby version join.
#
# --- Star Wars worlds ---
# The planet/ship maps live in /var/lib/minecraft/<name>/ (one folder per world).
# rsync them from your machine first:
#   rsync -a ./endor/        root@malleum.us:/var/lib/minecraft/endor/
#   rsync -a ./felucia_v1/   root@malleum.us:/var/lib/minecraft/felucia_v1/
#   rsync -a ./geonosis_battle/ root@malleum.us:/var/lib/minecraft/geonosis_battle/
#   rsync -a ./isd_v1/       root@malleum.us:/var/lib/minecraft/isd_v1/
#   rsync -a ./phoenix_fleet/ root@malleum.us:/var/lib/minecraft/phoenix_fleet/
#   rsync -a ./scarif_v1/    root@malleum.us:/var/lib/minecraft/scarif_v1/
#   rsync -a ./venator_v4/   root@malleum.us:/var/lib/minecraft/venator_v4/
#   chown -R minecraft:minecraft /var/lib/minecraft/*/
# Then import via RCON (one-time; Multiverse remembers across restarts):
#   RCON="mcrcon -H 127.0.0.1 -P 25575 -p $(sudo cat /var/lib/minecraft/rcon.secret)"
#   for w in endor felucia_v1 geonosis_battle isd_v1 phoenix_fleet scarif_v1 venator_v4; do
#     $RCON "mv import $w normal"
#   done
#
# --- Height extension (ISD map) ---
# The ISD map was built using a 2032-block height extender datapack. The datapack
# (2032-world-height.zip, bundled in this repo) is written to world/datapacks/
# on every start so the extended dimension type is registered globally before
# Paper loads any worlds. Confirmed working on 1.21.10.
#
# --- End battle scene (ISD vs Venator) ---
# Tested locally: Venator schematic is 1176W×328H×643L blocks.
# After a player with op connects, run these once (copy/paste into their chat):
#   ## Teleport to the End, paste Venator at centre facing south (+Z)
#   /mv tp world_the_end
#   /tp 0 100 -700
#   //schem load venator_v4
#   //paste -a                           # paste, skip air
#   /tp 0 100 700
#   //schem load venator_v4
#   //rotate 180
#   //paste -a                           # Venator facing north — mirrored battle
#   ## For the ISD: travel to isd_v1 world, select the whole ship with //wand,
#   ## //copy, return to world_the_end, position, //paste.
#
# --- Declarative vs first-run state ---
# Rewritten every start (edit mc.nix, not in-place):
#   server.properties, whitelist.json, ops.json
# Written once on first run (edit in-place afterwards):
#   rcon.secret, plugins/WorldGuard/config.yml, plugins/BlueMap/core.conf
#
# --- Before first deploy ---
# 1. Open 25565/tcp in the Oracle VCN Security List.
# 2. Starting the service accepts the Minecraft EULA (https://aka.ms/MinecraftEULA).
# 3. Add a DNS A record for map.malleum.us pointing at this host.
#
# Admin console:
#   mcrcon -H 127.0.0.1 -P 25575 -p "$(sudo cat /var/lib/minecraft/rcon.secret)" "<cmd>"
{
  unify.modules.mc.nixos = {
    pkgs,
    hostConfig,
    ...
  }: let
    inherit (pkgs) lib;

    mcVersion = "1.21.10";
    port = 25565;
    rconPort = 25575;
    # ~10G leaves the OS plenty of page-cache for region files. G1GC pause
    # times scale with heap size so bigger isn't always better on low player counts.
    heap = "10G";
    dataDir = "/var/lib/minecraft";
    java = pkgs.jdk21_headless;

    # Whitelisted players and operators (level 4). Add names here, rebuild.
    # UUIDs are resolved from the Mojang API and cached in .uuid-cache/.
    whitelistNames = ["malleum"];
    adminNames = ["malleum"];

    # Regenerated every start; rcon.password appended at runtime.
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
    propsFile = pkgs.writeText "mc-server.properties" (
      lib.concatLines (lib.mapAttrsToList (k: v: "${k}=${v}") serverProperties)
    );

    # Bundled in the repo — must live in world/datapacks/ so Paper registers the
    # extended dimension type BEFORE loading isd_v1 (which was saved with 2032-
    # block-height chunks). Without it, isd_v1 chunk loads fail with heightmap
    # size mismatch. Extends all three vanilla dimensions to height 2032.
    heightDatapack = ./2032-world-height.zip;

    # Aikar's flags — https://mcflags.emc.gs
    javaFlags = builtins.concatStringsSep " " [
      "-Xms${heap}" "-Xmx${heap}"
      "-XX:+UseG1GC" "-XX:+ParallelRefProcEnabled"
      "-XX:MaxGCPauseMillis=200" "-XX:+UnlockExperimentalVMOptions"
      "-XX:+DisableExplicitGC" "-XX:+AlwaysPreTouch"
      "-XX:G1NewSizePercent=30" "-XX:G1MaxNewSizePercent=40"
      "-XX:G1HeapRegionSize=8M" "-XX:G1ReservePercent=20"
      "-XX:G1HeapWastePercent=5" "-XX:G1MixedGCCountTarget=4"
      "-XX:InitiatingHeapOccupancyPercent=15"
      "-XX:G1MixedGCLiveThresholdPercent=90"
      "-XX:G1RSetUpdatingPauseTimePercent=5"
      "-XX:SurvivorRatio=32" "-XX:+PerfDisableSharedMem"
      "-XX:MaxTenuringThreshold=1"
      "-Dusing.aikars.flags=https://mcflags.emc.gs"
      "-Daikars.new.flags=true"
    ];
  in {
    users.groups.minecraft = {};
    users.users.minecraft = {
      isSystemUser = true;
      group = "minecraft";
      home = dataDir;
      description = "Minecraft Server";
    };
    users.users.${hostConfig.user.username}.extraGroups = ["minecraft"];

    environment.systemPackages = [pkgs.mcrcon];

    systemd.services.minecraft = {
      description = "Minecraft Server (Paper ${mcVersion} + Origins-Reborn)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.curl pkgs.jq];

      preStart = ''
        ua="malleum-nixos-minecraft (${hostConfig.user.email})"

        # Minecraft EULA — https://aka.ms/MinecraftEULA
        echo "eula=true" > eula.txt

        # Height-extender datapack: must be present BEFORE the server starts so
        # Paper registers the extended dimension type globally. isd_v1 chunks were
        # saved with 2032-block-height heightmaps; without this they fail to load.
        mkdir -p world/datapacks
        cp -f ${heightDatapack} world/datapacks/2032-world-height.zip

        # Paper jar (fetch-once)
        if [ ! -e "paper-${mcVersion}.jar" ]; then
          url=$(curl -fsSL -A "$ua" \
            "https://fill.papermc.io/v3/projects/paper/versions/${mcVersion}/builds/latest" \
            | jq -er '.downloads["server:default"].url')
          curl -fsSL -A "$ua" -o "paper-${mcVersion}.jar.part" "$url"
          mv "paper-${mcVersion}.jar.part" "paper-${mcVersion}.jar"
        fi
        ln -sfn "paper-${mcVersion}.jar" paper.jar

        # Plugins: fetch-once from Modrinth (newest stable for mcVersion, falling
        # back to newest overall). Delete a jar and restart to update it.
        mkdir -p plugins
        loaders='loaders=["paper","purpur","bukkit","spigot"]'
        fetch_plugin() { # $1=jar-name $2=modrinth-slug
          [ -e "plugins/$1.jar" ] && return 0
          api="https://api.modrinth.com/v2/project/$2/version?loaders=%5B%22paper%22%2C%22purpur%22%2C%22bukkit%22%5D"
          # Try version-matched first, fall back to latest
          url=$(curl -fsSL -A "$ua" "$api&game_versions=%5B%22${mcVersion}%22%5D" \
            | jq -er 'first(.[] | select(.version_type=="release")).files[0].url // .[0].files[0].url // empty') \
            || url=$(curl -fsSL -A "$ua" "$api" | jq -er '.[0].files[0].url') \
            || { echo "WARNING: could not resolve $1 ($2)"; return 0; }
          [ -z "$url" ] && { echo "WARNING: empty url for $1"; return 0; }
          curl -fsSL -A "$ua" -o "plugins/$1.jar.part" "$url" \
            && mv "plugins/$1.jar.part" "plugins/$1.jar" \
            || { echo "WARNING: download failed for $1"; rm -f "plugins/$1.jar.part"; }
        }

        fetch_plugin Origins-Reborn      origins-reborn    # server-side Origins
        fetch_plugin ViaVersion          viaversion        # newer clients can join
        fetch_plugin ViaBackwards        viabackwards      # older clients can join
        fetch_plugin CoreProtect         coreprotect       # block logging + rollback
        fetch_plugin Chunky              chunky            # chunk pregeneration
        fetch_plugin DynamicLights       dynamiclight      # held-torch glow (packet-only)
        fetch_plugin WorldGuard          worldguard        # anti-grief rules
        # EssentialsX intentionally omitted — adds /enderchest, /home, /tpa etc.
        # which change vanilla feel. Use RCON + op for admin commands instead.
        fetch_plugin BlueMap             bluemap           # live 3D web map
        fetch_plugin Multiverse-Core     multiverse-core   # extra worlds
        fetch_plugin Multiverse-Portals  multiverse-portals # portal blocks between worlds
        fetch_plugin Multiverse-Portals  multiverse-portals # portal blocks between worlds
        fetch_plugin FastAsyncWorldEdit  fastasyncworldedit # schematic copy/paste (ships)
        # DistantHorizonsSupport intentionally omitted — server plugin lags behind
        # client releases and shows "outdated" warning. DH works client-only fine.

        # RCON password (generated once, never in nix store)
        if [ ! -e rcon.secret ]; then
          umask 077
          head -c 512 /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 > rcon.secret
        fi

        # Declarative files — rewritten every start
        cat ${propsFile} > server.properties
        echo "rcon.password=$(cat rcon.secret)" >> server.properties

        resolve_uuid() {
          mkdir -p .uuid-cache
          if [ ! -s ".uuid-cache/$1" ]; then
            curl -fsSL -A "$ua" "https://api.mojang.com/users/profiles/minecraft/$1" \
              | jq -er '.id' \
              | sed -E 's/^(.{8})(.{4})(.{4})(.{4})(.{12})$/\1-\2-\3-\4-\5/' \
              > ".uuid-cache/$1"
            grep -qE '^[0-9a-f-]{36}$' ".uuid-cache/$1" || {
              rm -f ".uuid-cache/$1"; return 1
            }
          fi
          cat ".uuid-cache/$1"
        }
        gen_players() {
          players="[]"
          for n in "$@"; do
            id=$(resolve_uuid "$n") || return 1
            players=$(printf '%s' "$players" \
              | jq --arg u "$id" --arg n "$n" '. + [{uuid:$u,name:$n}]')
          done
          printf '%s' "$players"
        }
        if wl=$(gen_players ${toString whitelistNames}); then
          printf '%s\n' "$wl" > whitelist.json
        else
          echo "WARNING: uuid lookup failed; keeping existing whitelist.json"
        fi
        if ops=$(gen_players ${toString adminNames}); then
          printf '%s\n' "$ops" \
            | jq 'map(. + {level:4, bypassesPlayerLimit:true})' > ops.json
        else
          echo "WARNING: uuid lookup failed; keeping existing ops.json"
        fi

        # WorldGuard: disable creeper/enderman block damage globally.
        # Mob damage to players and all other vanilla behaviour is untouched.
        if [ ! -e plugins/WorldGuard/config.yml ]; then
          mkdir -p plugins/WorldGuard
          printf 'mobs:\n  block-creeper-block-damage: true\n  block-enderman-block-damage: true\n' \
            > plugins/WorldGuard/config.yml
        fi

        # BlueMap: pre-accept Mojang asset download (renders vanilla textures)
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
        TimeoutStopSec = 120; # Paper saves worlds on SIGTERM; give it time
        User = "minecraft";
        Group = "minecraft";
        StateDirectory = "minecraft";
        Environment = ["HOME=${dataDir}"];
        ProtectSystem = "full";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # BlueMap web server (port 8100) stays firewalled; expose only via nginx
    services.nginx.virtualHosts."map.malleum.us" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8100";
        proxyWebsockets = true;
      };
    };

    # Game port only; RCON (25575) and BlueMap (8100) are loopback-only.
    networking.firewall.allowedTCPPorts = [port];
  };
}
