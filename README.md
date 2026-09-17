<div align="center">

# nixos

**One flake for every machine I use: laptops, a desktop, and a cloud server.**

[unify](https://codeberg.org/quasigod/unify) · flake-parts · import-tree · home-manager · sops-nix · stylix

</div>

---

## Contents

- [Hosts](#hosts)
- [Everyday commands](#everyday-commands)
- [How the repo is put together](#how-the-repo-is-put-together)
- [Module tags](#module-tags)
- [Common tasks](#common-tasks)
- [Secrets](#secrets)
- [Desktop](#desktop)
- [Editor](#editor)
- [Small tools](#small-tools)

## Hosts

| Host | What it is | Notes |
| :--- | :--- | :--- |
| **magnus** | Desktop | Discrete AMD GPU, TV as the left monitor, games, Windows dual boot |
| **malleum** | Laptop | AMD APU |
| **manus** | Laptop | AMD APU, MT7925 WiFi, LG UltraGear external monitor |
| **minoris** | Laptop | The bare minimum: `efi gui lap`. Also the shape new hosts start from |
| **minimus** | Server | aarch64 Oracle Cloud box: Matrix, game servers, websites |

Each host is a single file, `hosts/<name>/<name>.nix`, that lists the
[module tags](#module-tags) it wants, next to its generated hardware config.

## Everyday commands

```sh
nh os switch                 # build and switch this host
nh os switch -u              # update flake inputs, then switch
nix fmt .                    # format every .nix file with alejandra
nix flake check              # evaluate every host and run the checks
nix run .#<script>           # run any script from modules/scripts without installing
```

Deploying to the server, building locally and copying the closure over SSH
(x86 hosts have aarch64 binfmt registered):

```sh
nh os switch . -H minimus --target-host minimus
```

Swap `--target-host minimus` for `--build-host minimus` to let the Ampere box
compile natively instead.

## How the repo is put together

```text
flake.nix     inputs only; outputs are every file under hosts/ and modules/
hosts/        one directory per machine
modules/
  hardware/   drivers, firmware quirks, input devices
  meta/       the flake itself: user, nix settings, formatting, bootstrap
  packages/   package sets, plus the auto-packaging of modules/scripts
  programs/   configured applications (jay, zsh, tmux, firefox, ...)
  scripts/    standalone tools, each one a flake package
  secrets/    sops-encrypted yaml and the modules that decrypt it
  services/   long-running things, desktop and server
  style/      stylix theme and wallpapers
  system/     boot, audio, network, locale, security
mvim/         the everyday neovim config, plain Lua
nixvim/       the full neovim build with language tooling
lib/          plain Nix helpers, not auto-imported
```

A few conventions carry most of the structure:

- **Everything is auto-imported.** [import-tree](https://github.com/vic/import-tree)
  loads every `.nix` file under `hosts/` and `modules/`. Adding a file is enough
  to make it take effect. No import lists to maintain.
- **A leading underscore opts out.** `_config.nix`, `_hardware-configuration.nix`
  and the like are skipped by import-tree and imported by hand from a sibling
  file. Use it for helpers and for anything that isn't a module.
- **Modules say where they apply.** With [unify](https://codeberg.org/quasigod/unify),
  a file writes to one of:
  - `unify.nixos` / `unify.home`: every host
  - `unify.modules.<tag>.nixos` / `.home`: only hosts that list `<tag>`

  System and home-manager config for the same feature live side by side in one
  file.
- **Host facts come from `hostConfig`.** Username, browser, flake path and
  hostname are defined once (`modules/meta/userConfig.nix`, `flakepath.nix`)
  and passed to every module as `hostConfig`.
- **Scripts are packages.** Every `_name.nix` in `modules/scripts` is built with
  `callPackage`, installed for the user, and exposed as `.#name`.

## Module tags

| Tag | Gives you |
| :--- | :--- |
| `gui` | The desktop: jay, login manager, audio, bluetooth, terminal, browsers, theme, notifications, keyring |
| `lap` | Battery and backlight handling |
| `efi` | systemd-boot |
| `dev` | Programming toolchains and the full `nixvim` build |
| `ai` | Claude Code, Cursor and other assistant CLIs |
| `cht` | Matrix (iamb) and Signal |
| `med` | Media players, OBS, Spotify, Vesktop, text-to-speech |
| `gam` | Games, the speedrun keyboard and mouse setup, waywall |
| `off` | LibreOffice, pandoc, spell checking |
| `doc` | Docker |
| `vrt` | Virtualisation tools |
| `prt` | Printing and network printer discovery |
| `wrk` | Work tooling |
| `src` | Build jay and iamb from their source flakes instead of the binary cache |
| `hyp` | Hyprland and waybar, kept as a backup session |
| `amd` | AMD GPU tuning, with APU workarounds kept off the desktop's discrete card |
| `ath` / `wif` | WiFi fixes for the Qualcomm WCN7850 and MediaTek MT7925 cards |
| `bt-audio` | Bluetooth audio stutter fixes for the WCN7850 combo card |
| `dbt` | Windows entry and the UEFI shell in the boot menu |
| `matrix` `grapple` `balefire` `mc` | Server services on minimus |

The authoritative list is `grep -rho 'unify\.modules\.[a-z-]*' modules | sort -u`.

## Common tasks

### Install a new machine

On a fresh NixOS install (not the live ISO), with network and a sudo user:

```sh
nix --extra-experimental-features 'nix-command flakes' \
  run github:malleum/nixos#bootstrap -- <hostname>
```

That clones this repo to `~/.config/nixos`, writes `hosts/<hostname>/` from a
minimal template, captures the hardware config, and switches. It needs the sops
age key. If the key is missing, the script asks for a magic-wormhole code, so
run `wormhole send ~/.config/sops/age/keys.txt` on a machine that has it. The
full notes are at the top of `modules/meta/bootstrap.nix`.

After it boots, add tags to the host file and `nh os switch`.

### Add a feature

1. Create a file in the matching `modules/` directory.
2. Write to `unify.modules.<tag>` for an opt-in feature, or to `unify.nixos` /
   `unify.home` for something every host should have.
3. Add the tag to the hosts that want it and switch.

### Add a script

Drop `modules/scripts/_name.nix` in (a `writeShellApplication`, `writeRustBin`
or any `{pkgs, ...}:` derivation). It is installed on every host and runnable as
`nix run .#name`.

### Commit hooks

```sh
nix run .#install-hooks      # or enter the dev shell: direnv / nix develop
```

Commits run alejandra on Nix and stylua on the Lua in `mvim/`.

## Secrets

Secrets are [sops-nix](https://github.com/Mic92/sops-nix) yaml under
`modules/secrets/`, encrypted to one personal age key plus each host's SSH host
key (see `.sops.yaml`).

```sh
sops modules/secrets/default.yaml    # edit in place, re-encrypts on save
sops updatekeys modules/secrets/*.yaml   # after adding a host key to .sops.yaml
```

The age key lives at `~/.config/sops/age/keys.txt`. Activation fails without
either it or a host key listed in `.sops.yaml`.

## Desktop

**jay** is the compositor. Its config is generated from
`modules/programs/jay/`, and jay reloads it automatically after a switch. If
the bar or anything else looks stale, `super-]` reloads the config and restarts
the status bar.

- Status bar: a small Rust program (`jay/_status.rs`) speaking i3bar JSON.
  Audio updates instantly; everything else refreshes every two seconds.
- Theme: stylix sets base16 colours once, and jay, the status bar, tmux, rofi,
  notifications and the lock screen all read from them.
- Hyprland (`hyp`) is a second session on the login screen, kept working as a
  fallback.

## Editor

Two neovim builds, both from this repo (`modules/meta/nvim.nix`):

| Command | Build | Use |
| :--- | :--- | :--- |
| `nvim`, `vi` | **mvim**: plain neovim plus the Lua in `mvim/`, no plugin manager | Everyday editing, on every host |
| `nixvim` | **nixvim**: LSP servers, formatters, linters bundled | `dev` hosts only; large closure |

mvim ships no language tooling of its own. It uses whatever is on `PATH`, and
`devinit` writes a per-project flake dev shell with the right servers and
formatters, loaded by direnv. `:help mvim` inside the editor documents the
keymaps; `mvim/tests/` holds its test suite.

## Small tools

| Command | Does |
| :--- | :--- |
| `devinit` | Write `flake.nix` + `.envrc` with the language servers a project needs |
| `duod` | Time of day as a base-12 fraction (`60000` is noon), and back: `duod 12:00`, `duod 6` |
| `chron` | Time of day in hundredths of a day (`50.0 00` is noon), and back: `chron 18:00`, `chron 75` |
| `jay-power-menu`, `jay-audio-switch`, ... | Desktop helpers bound to keys in jay |

`duod` and `chron` share their conversion code (`modules/scripts/_daytime.rs`),
tested by `nix flake check`. The matching qalculate units are described in
`modules/packages/qalculate_units.md`.

## TODO

- [ ] secrets: gpg keys, gitlab key
