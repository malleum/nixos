# CLAUDE.md — Minecraft server (mc.nix) work handoff

Session handoff for continuing work on the Minecraft server. Read this fully
before touching anything. Written 2026-07-04.

## What this is

A declarative Minecraft server defined entirely in this NixOS flake, running on
host **minimus** and reachable at **malleum.us:25565**. Modeled on the existing
`grapple.nix` pattern (a service module that runs a workload on minimus).

- Module: `modules/services/mc.nix` (the core deliverable).
- Enabled in: `hosts/minimus/minimus.nix` (via the `mc` entry in its module list).
- Server state lives in `/var/lib/minecraft` on minimus (systemd
  `StateDirectory=minecraft`, runs as user `minecraft`).
- The flake uses a `unify` module system (`unify.modules.mc.nixos`).

## Goals (what the user asked for)

1. **Server-side-only Origins** for Java MC — players join with vanilla clients,
   nothing installed locally. Chosen: **Origins-Reborn** (Paper plugin) + the
   **Origins-Fantasy** and **Origins-Magic** addons (all by cometcake575).
2. Reachable at malleum.us (DNS already points at minimus IP).
3. **Vanilla-feel helper plugins only** — performance, bug fixes, dynamic
   lighting, cross-version join. **No** gameplay-changing utility plugins
   (EssentialsX /home /tpa /enderchest etc. were explicitly removed).
4. **Star Wars custom maps as separate dimensions/worlds.** 1:1 capital ships
   (Imperial Star Destroyer + Venator) placed in the End ~1k+ blocks apart
   facing each other. Ships were pasted in-game with FastAsyncWorldEdit.
5. **As declarative as possible** — everything in this repo, regenerated on
   every service start via the `preStart` script in mc.nix.
6. Server rules: no creeper/enderman griefing (WorldGuard), difficulty easy,
   whitelist = `malleum`, first-spawn on Felucia at an exact block,
   online-mode=true, view-distance=16, heap 10G (server has 23GB RAM).
7. **Multiverse portals** linking planets bidirectionally, with visible obsidian
   portal frames (air interior; Multiverse triggers on walk-through).
8. **Per-dimension themed mob spawns** — each Star Wars planet gets fitting
   vanilla mobs (hostile + passive/food), balanced, not overwhelming. End left
   vanilla. Implemented with **MythicMobs** random spawns.
9. **Distant Horizons** server support, version-locked to the client mod.
10. Client side (separate from server): performance mods + Distant Horizons in a
    PrismLauncher instance. Already done (see "Client" below).

## Technologies

- **Paper 1.21.10**, Java 21 (`jdk21_headless`), Aikar's GC flags, heap 10G.
- Plugins (all fetched declaratively from Modrinth in `preStart`, fetch-once):
  Origins-Reborn (+ Fantasy + Magic), Multiverse-Core (v5.7.2-pre.2) +
  Multiverse-Portals, **MythicMobs 5.12.1** (themed spawns), FastAsyncWorldEdit,
  WorldGuard, ViaVersion + ViaBackwards (cross-version client join), CoreProtect,
  Chunky (chunk pregen, helps Distant Horizons), DynamicLights,
  DistantHorizonsSupport (server plugin, version 0.13.1).
- **Distant Horizons**: server plugin 0.13.1 supports DH client **3.0.0–3.0.3
  only**. Client is pinned to DH 3.0.3-b to match. Do not bump one without the
  other.
- **2032-world-height datapack** (`modules/services/2032-world-height.zip`):
  extends all dimensions to Y=2032 so the tall capital ships fit. Must be in the
  MAIN world's `datapacks/` folder before worlds load — mc.nix copies it to
  `world/datapacks/`. If it loads late, chunks fail with a heightmap size
  mismatch.
- RCON admin on 127.0.0.1:25575 (loopback only), via `mcrcon`. Password is in
  `/var/lib/minecraft/server.properties` (`rcon.password`).
- Worlds: `world`, `world_nether`, `world_the_end` (vanilla trio; ships are in
  `world_the_end`) plus Multiverse worlds `felucia_v1`, `geonosis_battle`,
  `endor`, `scarif_v1`.

## The problem currently being solved

**No mobs were spawning in any of the custom Star Wars worlds** (user reported
Felucia empty, and it affects the other custom maps too).

### Root cause

The themed spawns used MythicMobs random spawns with `Action: REPLACE`. REPLACE
hooks a vanilla `CreatureSpawnEvent` and swaps the mob — it only fires when the
vanilla engine would *naturally* spawn something there. The custom Star Wars
maps are hand-built, well-lit, and have few spawnable blocks near where players
are, so they produce almost no natural spawns → nothing to replace → empty
worlds. Diagnosed via `mm reload` logging `✓ Loaded 0 random spawns` and the MM
jar's default `config-spawning.yml` comment:
`# Generator used for ADD method. Can be NONE, CLUSTER, or LEGACY`.

### The fix (implemented, committed, deployed — pending final in-game check)

1. Switched `modules/services/mc-mythicmobs/randomspawns-starwars.yml` from
   `Action: REPLACE` to **`Action: ADD`** with a per-entry `Cooldown` (seconds)
   for density control. ADD makes MythicMobs proactively spawn themed mobs at
   generated spawn points around players, independent of vanilla spawning.
2. ADD requires a spawn-point generator. MythicMobs defaults
   `config-spawning.yml` → `RandomSpawning.Generator: NONE` (disabled). mc.nix
   `preStart` now `sed`s that to **`Generator: CLUSTER`** (idempotent, matches
   NONE/CLUSTER/LEGACY). This is the declarative gap that caused the bug: the
   generator was never enabled.
3. **Important**: MythicMobs reads `Generator` at plugin *enable*, not on
   `mm reload`. So a full service restart is required (a `mm reload` alone will
   load the 40 spawn definitions but the generator engine stays NONE from boot).
   The nix deploy restarts the service, which is why deploying — not just editing
   the live file — was necessary.

Commit: `mc: fix empty worlds — MythicMobs ADD spawns + Generator CLUSTER`
(pushed to origin/master, deployed to minimus).

## Current state (as of this handoff)

- Deployed to minimus and service restarted 2026-07-04 12:17:45 EDT.
- Verified: `Generator: CLUSTER` in live config, `✓ Loaded 40 random spawns`,
  service active, first-spawn-location valid.
- **NOT yet verified**: that mobs actually appear in-game. CLUSTER only generates
  spawn points **around online players**, and nobody was online at restart. This
  is the one open check.

### >>> NEXT STEP (do this first) <<<

Have the user (malleum) join malleum.us, stand in Felucia a minute, and confirm
mobs appear. To measure from the machine while they're online:

```
ssh minimus 'P=$(sudo grep ^rcon.password /var/lib/minecraft/server.properties|cut -d= -f2); \
  sudo /run/current-system/sw/bin/mcrcon -H 127.0.0.1 -P 25575 -p "$P" "mm mobs killall"'
```

`mm mobs killall` prints `Removed N Mythic Mobs!` — that N is how many themed
mobs are currently alive (it does kill them, but they respawn on cooldown). If N
stays 0 after a couple minutes with a player standing still in Felucia, the
generator still isn't producing spawns — see "If ADD/CLUSTER still yields
nothing" below.

### If ADD/CLUSTER still yields nothing

Things to try, roughly in order:
- Try `Generator: LEGACY` instead of CLUSTER (older, simpler, more aggressive).
  Change the `sed` target value in mc.nix preStart and redeploy.
- Drop `Reason: NATURAL` from the entries — if MM applies vanilla spawn rules
  (light level for hostiles, grass for animals) it may reject the custom terrain.
- Check `SpawnRadiusPerPlayer` (64) vs where the player stands — if they're on a
  ship/structure with no valid ground within radius, no points generate.
- Confirm the player world name matches the `Worlds:` field exactly
  (`felucia_v1`, `geonosis_battle`, `endor`, `scarif_v1`).
- Enable `mm debug 3`, reload, and grep the log for generation attempts.

## Also fixed earlier this session (already deployed/live)

- **First-spawn was landing in the overworld, not Felucia.** Multiverse v5 needs
  the exact-destination `e:` prefix; the config had the old v4 bare
  `felucia_v1:x,y,z` format → `Invalid destination in FirstSpawnLocation` → it
  fell back to the overworld world spawn. Set via
  `mv config first-spawn-location e:felucia_v1:728.5,-52,-260.5:176.96:0`.
  first-spawn-override fires only for players with no playerdata, so malleum's
  playerdata was deleted (while offline) to re-trigger it.
  NOTE: this was set with an `mv` command on the live server. Multiverse
  `config.yml` is **not** currently managed by mc.nix — see "Known gaps".
- The user may have run `/setworldspawn` in the overworld; that only sets the
  overworld fallback spawn and is beaten by a valid first-spawn. Left as-is.

## Known gaps / not-yet-declarative

- **Multiverse-Core `config.yml` is not generated by mc.nix.** first-spawn-
  override + first-spawn-location, `enforce-gamemode: false`, and respawn
  settings live only in the state dir. If `/var/lib/minecraft` is ever wiped,
  these reset. Consider adding a preStart step to pin them (same pattern as the
  MythicMobs Generator sed). The correct first-spawn value is
  `e:felucia_v1:728.5,-52,-260.5:176.96:0`.
- **Multiverse-Portals `portals.yml` is not managed by mc.nix** either. 8 portals
  are defined live (felucia<->geonosis, geonosis<->scarif, scarif<->endor,
  endor<->end). Multiverse-Portals rewrites this file from memory on graceful
  shutdown, so any hand-edit must be done while the server is fully dead
  (`pkill -9`), then start.
- Worlds themselves (the custom maps + pasted ships) are binary data in
  `/var/lib/minecraft`, not in the repo. A backup copy of the worlds lives on
  host **magnus** under `~/mc-local/server/` (world_the_end 261M has the ships,
  plus endor/felucia_v1/geonosis_battle/scarif_v1). That is the reset copy.

## Operational cheatsheet

RCON one-liner pattern (run from anywhere with ssh to minimus):
```
ssh minimus 'P=$(sudo grep ^rcon.password /var/lib/minecraft/server.properties|cut -d= -f2); \
  sudo /run/current-system/sw/bin/mcrcon -H 127.0.0.1 -P 25575 -p "$P" "<command>" | sed "s/\x1b\[[0-9;]*m//g"'
```
- Strip the `sed` if you want raw; it just removes color codes.
- Vanilla `/tp` from RCON goes to the overworld — use
  `execute in <dimension> run tp ...`, or `mvtp <player> <world>` for Multiverse
  worlds. `execute in` only knows the 3 vanilla dimensions, not the MV worlds.
- Custom MV worlds aren't targetable by `execute in`; run selectors as the player
  (`execute as <player> at @s run ...`) to resolve in their world.

Deploy flow (from a machine with this repo, after committing + pushing):
```
ssh minimus 'cd ~/.config/nixos && git pull && nh os switch -j 1 --cores 1'
```
This re-runs preStart (copies configs, sets Generator, etc.) and restarts the
minecraft service.

Manual spawn test (proves mob defs + engine, bypasses random spawns):
```
mm mobs spawn sw_pillager 2 felucia_v1,733,-15,-313,0,0
```
The 17 `sw_` mobs are plain vanilla-typed MythicMobs
(`modules/services/mc-mythicmobs/mobs-starwars.yml`).

## Themed spawn design (what spawns where)

Source: `modules/services/mc-mythicmobs/randomspawns-starwars.yml` (Action: ADD,
per-entry Chance + Cooldown seconds).
- **Geonosis** (execution arena / droid army): pillager, vindicator, husk, rare
  ravager + sparse rabbit.
- **Felucia** (fungal jungle): slime, witch, cave spider + chicken, cow.
- **Endor** (forest moon, richest wildlife): pillager + cow, sheep, chicken,
  wolf, fox.
- **Scarif** (tropical beach, Imperial garrison): drowned, guardian + turtle,
  chicken.
- **End**: intentionally left vanilla (endermen/shulkers).

## One external manual step (outside the machine)

The NixOS firewall opens 25565/tcp, but minimus is on Oracle Cloud — external
reachability also needs a **25565/tcp ingress rule in the Oracle VCN Security
List** (same place as the 80/443 rules for the website). If the server is
unreachable externally but bound locally, this is why.

## Waverider custom origin (waverider-origin/)

Custom Origins-Reborn addon origin, added 2026-07-05 on branch
`claude/waverider-origin-plugin-n9ylrc`. Java/Gradle project at
`waverider-origin/` (self-contained; user wants it in its own repo
eventually). Built jar is COMMITTED at `modules/services/Waverider-Origin.jar`
and copied to `plugins/` by mc.nix preStart on every start.

- Mechanics: walk/run on water+lava (client-side barrier packets + Speed III,
  no burn), sneak to sink; fluids are SOLID when landing from falls (splat)
  unless sneaking/diving; 2x fall + fly-into-wall damage; 2x breath drain;
  leather armor only (elytra allowed); vegetarian (built-in power). Wavecatch:
  sneak while falling within 10 blocks of a surface → real water block for 1s
  breaks the fall (1s cooldown on every attempt, even misses); catches from
  >3 blocks grant Speed/Regen/Night Vision 60s.
- v1.2.0: sneak-diving out of a fall is limited to vanilla safe-fall height
  (fallDistance ≤ 3) — past that the floor stays solid even while sneaking and
  only a Wavecatch saves you. Clutch over open water: player falls through the
  clutch block onto the (still solid) body surface and stays standing unless
  still holding shift (fall reset re-arms sneak-to-sink). FluidWalker treats
  clutch water as fall-through in all three checks (feet bail, downward scan,
  3x3 surface test).
- v1.1.0 fixes after first play-test: (1) fall damage onto fluids now applies —
  requires `allow-flight=true` in server.properties (set by mc.nix); the old
  per-player setAllowFlight suppressed ALL fall damage (vanilla skips fall
  damage for mayfly players). Do NOT reintroduce setAllowFlight. (2) Speed III
  (amplifier 2, `fluid_walker.speed-amplifier`) so sprinting (~9 b/s) beats
  boats (~8 b/s); user asked for at least Speed 3. (3) water floor uses
  WATERLOGGED barriers so the water still renders under your feet (no dry
  patch); lava can't be fluid-logged so lava keeps plain barriers.
- Ability keys: waverider:{fluid_walker,water_clutch,hard_landing,
  shallow_lungs,leather_only}. Config lands in Origins-Reborn's
  ability-config.yml under `waverider:`; text in translations.yml.
- Rebuild: `cd waverider-origin && gradle build && cp
  build/libs/Waverider-Origin-*.jar ../modules/services/Waverider-Origin.jar`.
  Deps: paper-api 1.21.10 (papermc repo) + maven.modrinth:origins-reborn
  (compileOnly). Verified: compiles, loads on Paper 1.21.10 alongside
  Origins-Reborn 2.10.9, origin JSON parses, abilities register.
- NOT yet play-tested in game (needs a real client to walk on water, test
  clutch timing, fly-kick suppression, and lava-walk feel).

## Persistent memory

There's operational memory at
`~/.claude/projects/-home-joshammer--config-nixos/memory/` (see `MEMORY.md`,
esp. `mc_local_server.md`) covering reliable start/stop, RCON, portal quirks,
chunk loading, and Multiverse world TP. Read it too.
