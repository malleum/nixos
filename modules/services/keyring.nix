# Session secret service (GNOME Keyring via libsecret).
#
# Jay is not a GNOME/KDE session, so Electron/Chromium cannot discover a
# password store and fall back to `basic` (hardcoded key). That is why Cursor
# MCP OAuth failed with "Encryption is not available" and why Brave was
# wrapped with `--password-store=basic`.
#
# Unlock is empty-password, not the greetd login password. A PAM unlock
# would pop a second password dialog whenever the keyring password does
# not match (including the first-run "create a keyring" prompt). swaylock
# PAM is left alone so screen unlock stays the existing jay-lock path.
#
# GTK/libsecret apps talk to the daemon over D-Bus with no flags. Electron
# still needs `--password-store=gnome-libsecret` because XDG_CURRENT_DESKTOP
# is `jay` and Chromium will not auto-select the libsecret backend.
{
  unify.modules.gui.nixos = {
    lib,
    pkgs,
    ...
  }: {
    programs.dconf.enable = true;
    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;
    # Default-on whenever gnome-keyring is enabled. We only want secrets,
    # not an SSH agent that would steal SSH_AUTH_SOCK from identityFile SSH.
    services.gnome.gcr-ssh-agent.enable = false;

    # The gnome-keyring module turns this on for `login`; greetd includes
    # that stack. Force it off so tuigreet never grows a keyring prompt.
    security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
    security.pam.services.greetd.enableGnomeKeyring = lib.mkForce false;

    environment.systemPackages = [pkgs.libsecret];
  };

  unify.modules.gui.home = {
    lib,
    pkgs,
    ...
  }: let
    emptyLoginKeyring = pkgs.writeText "login.keyring" ''
      [keyring]
      display-name=login
      ctime=0
      mtime=0
      lock-on-idle=false
      lock-after=false
    '';

    unlock = pkgs.writeShellScript "gnome-keyring-unlock-empty" ''
      set -eu
      dir="''${XDG_RUNTIME_DIR}/keyring"
      daemon=${pkgs.gnome-keyring}/bin/gnome-keyring-daemon
      busctl=${pkgs.systemd}/bin/busctl
      i=0
      while [ "$i" -lt 40 ]; do
        i=$((i + 1))
        if [ -S "$dir/control" ]; then
          ${pkgs.coreutils}/bin/printf "" | "$daemon" --control-directory="$dir" --unlock >/dev/null 2>&1 || true
          locked=$("$busctl" --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked 2>/dev/null || true)
          case "$locked" in
            *false*) exit 0 ;;
          esac
        fi
        ${pkgs.coreutils}/bin/sleep 0.25
      done
      exit 1
    '';
  in {
    services.gnome-keyring = {
      enable = true;
      components = ["secrets"];
    };

    systemd.user.services = {
      gnome-keyring.Service.ExecStart = lib.mkForce "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --foreground --components=secrets --control-directory=%t/keyring";

      # Separate unit: `--unlock` as ExecStartPost of the daemon itself
      # tries to become the secret service (same cgroup) and then systemd
      # kills the daemon when the post script fails.
      gnome-keyring-unlock = {
        Unit = {
          Description = "Unlock GNOME Keyring (empty password)";
          After = ["gnome-keyring.service"];
          Requires = ["gnome-keyring.service"];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${unlock}";
        };
        Install.WantedBy = ["gnome-keyring.service"];
      };
    };

    # Seed once. Never overwrite: stored secrets live in this file.
    home.activation.seedEmptyLoginKeyring = lib.hm.dag.entryAfter ["writeBoundary"] ''
      dir="$HOME/.local/share/keyrings"
      run mkdir -p "$dir"
      if [ ! -f "$dir/login.keyring" ]; then
        run cp ${emptyLoginKeyring} "$dir/login.keyring"
      fi
      if [ ! -f "$dir/default" ]; then
        run printf '%s\n' login > "$dir/default"
      fi
    '';
  };
}
