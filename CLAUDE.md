# CLAUDE.md

NixOS flake for hosts `malleum`, `magnus`, `manus`, `minimus`. Uses the `unify`
module system (`unify.modules.<name>.nixos`, `unify.hosts.nixos.<host>`) on top
of flake-parts + import-tree, so every file under `hosts/` and `modules/` is
picked up automatically.

Rebuild with `nh os switch`, not a raw `nix build` of the toplevel.

## Minecraft server

The malleum.us Minecraft server **no longer lives here**. It moved to
<https://github.com/malleum/mc> on 2026-07-28 and is consumed as the `mc` flake
input. That repo holds the NixOS module, the bundled assets (height-extender
datapack, MythicMobs themed spawns) and the Waverider origin plugin source.

What remains here is `modules/services/mc.nix` — a shim that imports
`inputs.mc.nixosModules.minecraft` into the unify module `mc` (enabled on
minimus) and sets the host-specific options: whitelist, admins, contact email,
group members. Everything else is an option on `services.malleum-minecraft`,
documented inline in the mc repo's `nix/module.nix`.

For anything about the server itself — the worlds, plugins, spawn hub,
MythicMobs spawn tuning, RCON cheatsheet, the Waverider origin, open questions —
read `CLAUDE.md` in the mc repo (`~/documents/gh/mc/CLAUDE.md`).

To ship a server change:

```sh
# in ~/documents/gh/mc
git commit && git push

# here
nix flake update mc && git commit -am 'flake: bump mc' && git push
ssh minimus 'cd ~/.config/nixos && git pull && nh os switch -j 1 --cores 1'
```

## Formatting and hooks

`nix fmt` runs alejandra over the tree. prek (a Rust pre-commit) runs the same
formatter on commit plus a `readme-tree` hook that regenerates the README
layout section from `git ls-files`. Install once with `nix run .#install-hooks`,
or just enter `nix develop`. If a commit is refused with "files were modified by
this hook", restage and commit again.

New files must be `git add`ed before they are visible to the flake at all —
untracked files do not exist as far as `git+file://` is concerned.

## Persistent memory

Operational memory lives at
`~/.claude/projects/-home-joshammer--config-nixos/memory/` (see `MEMORY.md`).
