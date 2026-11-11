# Session secret service (GNOME Keyring via libsecret).
#
# Jay is not a GNOME/KDE session, so Electron/Chromium cannot discover a
# password store and fall back to `basic` (hardcoded key). That is why Claude
# Desktop warned "No system keyring is available" and why Brave was wrapped
# with `--password-store=basic`.
#
# The keyring is encrypted with the login password and unlocked by logging in:
# pam_gnome_keyring keeps the password typed at greetd, starts the daemon when
# the session opens and unlocks the "login" keyring with it. There is no
# second prompt as long as the two passwords are the same. A first login on a
# new machine creates the keyring with that password, so there is nothing to
# set up.
#
# They stop being the same when the login password changes, because it comes
# from sops (meta/user.nix), not `passwd`, so PAM never sees the change. After
# changing the hash: Seahorse -> right-click "Login" -> Change Password, on
# each machine. Until then every login asks for the old password in a dialog.
#
# A machine that still has the old plaintext, empty-password keyring needs no
# Seahorse step: it opens as before, and the first write after a login through
# PAM saves it encrypted with the login password, items intact (checked in a
# VM, 2026-11-11). To force that write:
#   printf x | secret-tool store --label=migrate migrate once
#   secret-tool clear migrate once
#   head -c 12 ~/.local/share/keyrings/login.keyring    # want GnomeKeyring
#
# Nothing here starts the daemon. PAM starts it at login; the first program to
# ask for org.freedesktop.secrets on the session bus finishes the job through
# D-Bus activation. swaylock is left out on purpose: the keyring stays open
# for the whole session, so unlocking the screen has nothing to unlock.
#
# GTK/libsecret apps talk to the daemon over D-Bus with no flags. Electron
# still needs `--password-store=gnome-libsecret` because XDG_CURRENT_DESKTOP
# is `jay` and Chromium will not auto-select the libsecret backend.
{
  flake.modules.nixos.gui = {pkgs, ...}: {
    programs.dconf.enable = true;
    programs.seahorse.enable = true;

    # Also turns on pam_gnome_keyring for `login`, which greetd's own PAM
    # service includes wholesale.
    services.gnome.gnome-keyring.enable = true;
    # Default-on whenever gnome-keyring is enabled. We only want secrets,
    # not an SSH agent that would steal SSH_AUTH_SOCK from identityFile SSH.
    services.gnome.gcr-ssh-agent.enable = false;

    environment.systemPackages = [pkgs.libsecret];
  };
}
