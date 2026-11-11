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
{
  flake.modules.nixos.gui = {pkgs, ...}: {
    # System-wide, not home.packages: polkit only reads actions from the system
    # profile, and com.bitwarden.Bitwarden.unlock (auth_self, so the login
    # password) is what system-authentication unlock asks for. The prompt is
    # drawn by the polkit-agent unit in jay/default.nix.
    environment.systemPackages = [pkgs.bitwarden-desktop];
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
