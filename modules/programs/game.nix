{
  unify.modules.gam.nixos = {pkgs, ...}: {
    services.flatpak.enable = true;
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraPackages = with pkgs; [
        gtk3
        glib
        xorg.libXrandr
        xorg.libX11
      ];
    };
  };
}
