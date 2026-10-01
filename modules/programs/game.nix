{
  flake.modules.nixos.gam = {pkgs, ...}: {
    services.flatpak.enable = true;
    environment.systemPackages = [pkgs.gamescope];
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraPackages = with pkgs; [
        gtk3
        glib
        libxrandr
        libx11
      ];
    };
  };
}
