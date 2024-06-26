{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.base.progs.enable {
    virtualisation = {
      libvirtd.enable = true;
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
    };

    programs = {
      adb.enable = true;
      dconf.enable = true;
      nix-ld = {
        enable = true;
        libraries = with pkgs; [glib];
      };
      steam = {
        enable = true;
        gamescopeSession.enable = true;
      };
    };
  };
}
