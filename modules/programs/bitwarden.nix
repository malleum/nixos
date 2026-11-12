# Bitwarden desktop, running in the tray for the whole session so the browser
# extensions can unlock through it ("Unlock with system authentication").
#
# Nothing here wires up the browsers. The app does that itself on every start:
# it copies its proxy into ~/.mozilla/native-messaging-hosts (and Brave's
# NativeMessagingHosts) and writes com.8bit.bitwarden.json beside it, then
# starts listening. Do NOT hand that manifest to
# programs.firefox.nativeMessagingHosts: a store symlink there makes the write
# fail, and the listener is started in the same try block, so the integration
# dies with it.
#
# Per-machine setup, by hand, once. None of it can be declared: both the app
# and the extension keep these in their own mutable state, keyed by account
# id, next to the encrypted vault (~/.config/Bitwarden/data.json, and the
# extension's browser storage), and turning on system-authentication unlock
# also enrols a key in the login keyring -- it is not just a flag.
#
#   Desktop app (log in with the master password, then Settings -> Security):
#     Timeout                                       On restart
#     Timeout action                                Lock
#     Unlock with PIN                               off
#     Unlock with system authentication             on
#     Require master password or PIN on app restart off
#
#   Browser extension (log in, then Settings -> Account security):
#     Unlock with biometrics                        on (accept the permission)
#     Ask for biometrics on launch                  on
#     Unlock with PIN                               off
#     Timeout                                       On browser restart
#     Timeout action                                Lock
#
# After that the login password is the only one typed: it opens the keyring,
# the keyring holds the vault key, and the polkit rule below approves the
# unlock without a prompt. The extension still needs its popup opened once
# per browser start. Do not set its timeout to Never: that parks the vault key
# in the browser profile, readable by anyone holding an unencrypted drive.
{
  flake.modules.nixos.gui = {
    hostConfig,
    pkgs,
    ...
  }: {
    # System-wide, not home.packages: polkit only reads actions from the system
    # profile, and com.bitwarden.Bitwarden.unlock is what system-authentication
    # unlock asks for.
    environment.systemPackages = [pkgs.bitwarden-desktop];

    # The action ships as auth_self, i.e. a prompt for the login password on
    # every unlock (once for the app after login, once per browser restart).
    # Answer it without asking instead: logging in is the only password.
    #
    # This gives up nothing against other programs. With "Require master
    # password or PIN on app restart" off, the vault key already sits in the
    # login keyring, which any process of this user can read; the prompt only
    # ever gated Bitwarden's own UI. What it does give up is the prompt as a
    # check on whoever is at an unlocked session -- lock the screen.
    #
    # No `subject.local && subject.active` test, on purpose. The app runs as a
    # systemd user unit, which belongs to no login session, so polkit falls
    # back to the user's "display" session -- and on a host with an ssh login
    # open that can be the ssh one (remote), making both false and the unlock
    # fail with "Authentication failed". Matching on the user alone loses
    # nothing: an ssh login as this user can read the keyring directly.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "com.bitwarden.Bitwarden.unlock" &&
            subject.user == "${hostConfig.user.username}") {
          return polkit.Result.YES;
        }
      });
    '';
  };

  flake.modules.homeManager.gui = {
    lib,
    pkgs,
    ...
  }: let
    mkSessionUnit = import ./jay/_session-unit.nix {inherit lib pkgs;};
  in {
    # A supervised daemon, not an app opened at login: if it is not running the
    # extensions fall back to asking for the master password. Quitting it from
    # the tray therefore brings it back (locked) two seconds later.
    #
    # --autostart is the app's own flag for "start without showing a window".
    # Running `bitwarden` again (rofi) raises the window of this instance, which
    # is also the way in on hosts with no tray (no `src` tag).
    systemd.user.services.bitwarden =
      lib.recursiveUpdate (mkSessionUnit {
        description = "Bitwarden desktop (tray)";
        exec = "${pkgs.bitwarden-desktop}/bin/bitwarden --autostart";
      }) {
        # Start after the tray host so the icon has somewhere to register.
        Unit.After = ["jay-session.target" "wl-tray-bridge.service"];
        # User units do not see jay's env block; without this the wrapper skips
        # its Wayland flags and Electron goes looking for X11.
        Service.Environment = "NIXOS_OZONE_WL=1";
      };
  };
}
