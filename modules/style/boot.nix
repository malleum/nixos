{
  # Themed boot splash with a per-boot RANDOM logo.
  #
  # Drop any number of *.png files in ./plymouth-logos and one is picked at
  # random on every boot. Randomness comes from /dev/urandom in the initrd
  # (kernel-seeded, unlike plymouth's own RNG which repeats each boot).
  #
  # Fail-safe: if selection fails for ANY reason (no pngs, unreadable, copy
  # error), no logo.png is produced and the splash shows only the themed
  # background — never a broken/garbage icon.
  unify.modules.gui.nixos = {
    pkgs,
    config,
    lib,
    ...
  }: let
    hexChars = {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      "a" = 10;
      "b" = 11;
      "c" = 12;
      "d" = 13;
      "e" = 14;
      "f" = 15;
    };
    # Background color = base16 base00, as plymouth 0..1 float channels.
    base00 = config.stylix.base16Scheme.base00;
    hexByte = off: let
      s = lib.toLower (builtins.substring off 2 base00);
    in
      hexChars.${builtins.substring 0 1 s} * 16 + hexChars.${builtins.substring 1 1 s};
    chan = off: toString (hexByte off * 1.0 / 255.0);
    bgR = chan 0;
    bgG = chan 2;
    bgB = chan 4;

    logoDir = ./plymouth-logos;

    # Plymouth script plugin. Loads logo.png from ImageDir (a runtime tmpfs);
    # if it's absent/invalid, only the background is drawn (guarded).
    plyScript = pkgs.writeText "random-logo.script" ''
      cx = Window.GetWidth() / 2;
      cy = Window.GetHeight() / 2;

      Window.SetBackgroundTopColor(${bgR}, ${bgG}, ${bgB});
      Window.SetBackgroundBottomColor(${bgR}, ${bgG}, ${bgB});

      has_logo = 0;
      logo.image = Image("logo.png");
      if (logo.image) {
        has_logo = 1;
        logo.sprite = Sprite(logo.image);
        logo.sprite.SetPosition(
          cx - logo.image.GetWidth() / 2,
          cy - logo.image.GetHeight() / 2,
          1
        );

        spin_third = 32;
        spin_max = spin_third * 3;
        ri = 0;
        for (t = 0; t < 3; t++) {
          for (i = 0; i < spin_third; i++) {
            st = i / spin_third;
            ang = (t + ((Math.Sin(Math.Pi * (st - 0.5)) / 2) + 0.5)) / 3;
            logo.spin[ri] = logo.image.Rotate(2 * Math.Pi * ang);
            ri++;
          }
        }
        logo.idx = 0;
        logo.cnt = spin_max;
      }

      fun refresh () {
        if (has_logo) {
          logo.idx = (logo.idx + 1) % (logo.cnt * 2);
          logo.sprite.SetImage(logo.spin[Math.Int(logo.idx / 2)]);
        }
      }
      Plymouth.SetRefreshFunction(refresh);
    '';

    plyFile = pkgs.writeText "random-logo.plymouth" ''
      [Plymouth Theme]
      Name=Random Logo
      ModuleName=script

      [script]
      ImageDir=/run/plymouth-logo
      ScriptFile=${plyScript}
    '';

    theme = pkgs.runCommand "plymouth-theme-random-logo" {} ''
      d=$out/share/plymouth/themes/random-logo
      mkdir -p "$d"
      cp ${plyFile} "$d/random-logo.plymouth"
    '';

    # Runs in the initrd, before plymouth-start. Picks a random png and copies
    # it (atomically) to /run/plymouth-logo/logo.png. Always exits 0.
    pickLogo = pkgs.writeShellScript "plymouth-random-logo" ''
      set -u
      co=${pkgs.coreutils}/bin
      out=/run/plymouth-logo
      target="$out/logo.png"

      "$co/mkdir" -p "$out" || exit 0

      shopt -s nullglob
      logos=(${logoDir}/*.png)
      if [ "''${#logos[@]}" -eq 0 ]; then
        "$co/rm" -f "$target" 2>/dev/null || true
        exit 0
      fi

      rnd=$("$co/od" -An -N2 -tu2 /dev/urandom 2>/dev/null | "$co/tr" -dc '0-9')
      if [ -z "$rnd" ]; then
        "$co/rm" -f "$target" 2>/dev/null || true
        exit 0
      fi

      idx=$(( rnd % ''${#logos[@]} ))
      chosen="''${logos[$idx]}"

      tmp="$out/.logo.tmp.png"
      if "$co/cp" -- "$chosen" "$tmp" 2>/dev/null \
        && "$co/mv" -f -- "$tmp" "$target" 2>/dev/null; then
        exit 0
      fi
      "$co/rm" -f "$tmp" "$target" 2>/dev/null || true
      exit 0
    '';
  in {
    # One theme definition: disable stylix's plymouth so ours wins.
    stylix.targets.plymouth.enable = lib.mkForce false;

    boot = {
      plymouth = {
        enable = true;
        theme = "random-logo";
        themePackages = [theme];
      };
      # Quiet boot so the splash isn't interrupted by log spam.
      # Tradeoff: hides early-boot messages — drop `quiet` (or hit Esc) to debug.
      consoleLogLevel = 0;
      kernelParams = ["quiet" "udev.log_level=3"];
      initrd = {
        verbose = false;
        systemd.services.plymouth-random-logo = {
          description = "Select a random Plymouth logo";
          wantedBy = ["initrd.target"];
          before = ["plymouth-start.service"];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pickLogo;
          };
        };
      };
    };
  };
}
