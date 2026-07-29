# Turns a stock NixOS install into one of these hosts in one command: clone the
# repo to ~/.config/nixos, write the host file from a minimal template, capture
# the hardware config, stage it, switch, offer to reboot.
#
#   nix --extra-experimental-features 'nix-command flakes' \
#     run github:malleum/nixos#bootstrap -- <hostname>
#
# The --extra-experimental-features is needed because a stock NixOS install has
# neither nix-command nor flakes enabled; this repo turns them on, but not until
# after the first switch.
#
# RUN THIS AFTER THE INSTALLER, ON THE INSTALLED SYSTEM -- not from the live
# ISO. `nixos-generate-config` reads the *running* system's mounted
# filesystems, so on live media it would describe the ISO's squashfs rather
# than your disk, and `nixos-rebuild switch` switches the running system rather
# than installing to one. Installing from the ISO is what nixos-install (or
# nixos-anywhere) is for.
#
# Prerequisites:
#   * NixOS installed via the graphical installer and booted, with network
#   * a user with sudo (the installer's user is fine)
#   * the sops age key at ~/.config/sops/age/keys.txt -- every host pulls in
#     modules/secrets/sops.nix, and activation fails without it. If it is
#     missing the script prompts for a magic-wormhole code and fetches it, so
#     on a machine that has the key just run:
#       wormhole send ~/.config/sops/age/keys.txt
#
# One thing the installer will not have done: this config's user is `joshammer`
# (modules/meta/userConfig.nix). If the installer created a differently-named
# account, the switch adds joshammer with no password -- set one with
# `sudo passwd joshammer` before rebooting, or you cannot log in.
#
# The template takes the smallest module set that still gives a usable laptop,
# and nothing in it builds from source. Notably it omits `src`, so jay and iamb
# come prebuilt from the binary cache instead of needing a Rust toolchain, and
# omits `hyp`, so Hyprland is never fetched. Adding a module later is a one-line
# edit in the generated host file, which lists the options in a comment.
{
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    repo = "https://github.com/malleum/nixos";

    # A store file rather than an inline heredoc: interpolating a multi-line
    # Nix string into an indented shell heredoc mangles the leading whitespace.
    # @HOSTNAME@ is substituted at run time.
    hostTemplate = pkgs.writeText "host-template.nix" ''
      {config, ...}: let
        inherit (config.unify) modules;

        hostName = "@HOSTNAME@";
      in {
        unify.hosts.nixos.''${hostName} = {config, ...}: let
          inherit (config.user) username;
        in {
          # Minimal usable laptop. Add as needed:
          #   amd / wif  hardware quirks      hyp  hyprland as a second session
          #   dev        toolchains           cht  matrix + signal
          #   gam        games                med  players, obs, spotify
          #   off        libreoffice          ai   assistant CLIs
          #   doc        docker               vrt  qemu / quickemu
          #   wrk        work tooling         src  build jay+iamb from source
          modules = builtins.attrValues {
            inherit
              (modules)
              efi
              gui
              lap
              ;
          };

          nixos.imports = [./_hardware-configuration.nix];
          users.''${username} = {inherit (config) modules;};
        };
      }
    '';
  in {
    packages.bootstrap = pkgs.writeShellApplication {
      name = "bootstrap";
      runtimeInputs = with pkgs; [git nixos-install-tools coreutils gnused gnugrep findutils util-linux magic-wormhole];
      text = ''
        if [ $# -ne 1 ]; then
          echo "usage: bootstrap <hostname>" >&2
          exit 2
        fi
        host="$1"

        case "$host" in
          "" | *[!a-z0-9-]*)
            echo "bootstrap: '$host' must be lowercase letters, digits or dashes" >&2
            exit 2 ;;
        esac

        # Live media has an overlay/tmpfs root. Generating a hardware config
        # there would describe the ISO, not the disk, and the switch would
        # apply to the ramdisk -- so refuse rather than produce a broken host.
        rootfs=$(findmnt -no FSTYPE / 2>/dev/null || echo unknown)
        case "$rootfs" in
          overlay | tmpfs | squashfs)
            echo "bootstrap: / is a $rootfs -- this looks like the live installer." >&2
            echo "  Install NixOS first, boot it, then run this on the installed system." >&2
            exit 1 ;;
        esac

        # Every host imports modules/secrets/sops.nix, so activation fails
        # without this key. Rather than bailing, offer to receive it over
        # magic-wormhole from a machine that already has it:
        #     wormhole send ~/.config/sops/age/keys.txt
        age_key="''${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
        if [ ! -f "$age_key" ]; then
          echo "==> no sops age key at $age_key"
          echo "    On a machine that has it, run:"
          echo "      wormhole send ~/.config/sops/age/keys.txt"
          echo
          read -r -p "    wormhole code (blank to abort): " code
          if [ -z "$code" ]; then
            echo "bootstrap: no key and no wormhole code -- aborting" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$age_key")"
          # Receive into a temp dir so a mistyped code or a wrong file cannot
          # clobber anything, then move it into place ourselves.
          recv_dir=$(mktemp -d)
          trap 'rm -rf "$recv_dir"' EXIT

          if ! (cd "$recv_dir" && wormhole receive --accept-file "$code"); then
            echo "bootstrap: wormhole transfer failed" >&2
            exit 1
          fi

          received=$(find "$recv_dir" -type f | head -1)
          if [ -z "$received" ]; then
            echo "bootstrap: wormhole produced no file" >&2
            exit 1
          fi

          # Sanity-check before trusting it: an age identity file has this
          # header. Catches sending the wrong file far more cheaply than a
          # failed activation would.
          if ! grep -q "AGE-SECRET-KEY-" "$received"; then
            echo "bootstrap: $(basename "$received") does not look like an age key" >&2
            echo "  (expected a line containing AGE-SECRET-KEY-)" >&2
            exit 1
          fi

          install -m 600 -D "$received" "$age_key"
          echo "==> key installed at $age_key"
        fi

        repo_dir="$HOME/.config/nixos"

        if [ -d "$repo_dir/.git" ]; then
          echo "==> repo already present at $repo_dir"
        else
          echo "==> cloning ${repo} into $repo_dir"
          mkdir -p "$(dirname "$repo_dir")"
          git clone ${repo} "$repo_dir"
        fi
        cd "$repo_dir"

        if [ -e "hosts/$host" ]; then
          echo "bootstrap: hosts/$host already exists -- refusing to overwrite" >&2
          exit 1
        fi

        echo "==> writing hosts/$host/$host.nix"
        mkdir -p "hosts/$host"
        sed "s/@HOSTNAME@/$host/g" ${hostTemplate} > "hosts/$host/$host.nix"

        # The full generated config, not --no-filesystems: the fileSystems and
        # boot.initrd blocks are what make the result bootable, and the
        # generator already handles the ordinary single-disk layout.
        echo "==> capturing hardware configuration"
        nixos-generate-config --show-hardware-config \
          > "hosts/$host/_hardware-configuration.nix"

        # Untracked files do not exist as far as a git flake is concerned, so
        # this has to happen before the build, not after it.
        echo "==> staging (a git flake cannot see untracked files)"
        git add "hosts/$host"

        echo "==> building and switching to .#$host"
        if sudo nixos-rebuild switch --flake ".#$host"; then
          echo
          echo "==> switched. Commit once you are happy:"
          echo "      cd $repo_dir && git commit -m 'add host $host'"
          echo
          read -r -p "reboot now? [y/N] " ans
          case "$ans" in
            [yY]*) sudo reboot ;;
            *) echo "not rebooting -- run 'sudo reboot' when ready" ;;
          esac
        else
          echo "bootstrap: switch failed. hosts/$host is staged but uncommitted." >&2
          exit 1
        fi
      '';
    };

    apps.bootstrap = {
      type = "app";
      program = "${config.packages.bootstrap}/bin/bootstrap";
    };
  };
}
