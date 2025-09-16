{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [./firefox.nix];

  config = lib.mkIf config.base.progs.enable {

    programs = {
      gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-curses;
      };
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [obs-pipewire-audio-capture wlrobs];
      };
      adb.enable = true;
      dconf.enable = true;
      nix-ld = {
        enable = true;
        libraries = with pkgs; [glib];
      };
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
      chromium = {
        enable = true;
        extraOpts = {
          "BraveVPNDisabled" = true;
          "BraveWalletDisabled" = true;
        };
      };
    };
  };
}
