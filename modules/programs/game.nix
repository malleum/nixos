{
  unify.modules.gam.nixos = {pkgs, ...}: {
    services = {
      flatpak.enable = true;
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };
  };
}
