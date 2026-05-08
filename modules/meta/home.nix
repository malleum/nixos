{
  unify = {
    home = {
      hostConfig,
      lib,
      pkgs,
      ...
    }: let
      inherit
        (hostConfig.user)
        username
        homeDirectory
        configHome
        ;
    in {
      home = {
        inherit username homeDirectory;
        enableNixpkgsReleaseCheck = false;
      };

      gtk.gtk4.theme = null;
      xdg.userDirs.setSessionVariables = false;
      programs.git.signing.format = null;

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
      backupFileExtension = "bak";
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
