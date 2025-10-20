{
  unify = {
    home = {
      hostConfig,
      lib,
      ...
    }: let
      inherit (hostConfig.user) username homeDirectory configHome;
    in {
      home = {
        inherit username homeDirectory;
        enableNixpkgsReleaseCheck = false;
      };

      news = {
        display = "silent";
        entries = lib.mkForce [];
      };

      xdg = {
        enable = true;
        inherit configHome;
      };
    };

    nixos.home-manager = {
      backupFileExtension = "bakup";

      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
