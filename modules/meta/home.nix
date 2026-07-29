{
  unify = {
    home = {
      hostConfig,
      lib,
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

      gtk.gtk4.theme = lib.mkForce null;
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
      # Overwrite colliding files rather than leaving .bak clutter behind.
      # backupCommand runs on each pre-existing file instead of aborting
      # activation; backupFileExtension would move it aside forever.
      backupCommand = "rm -f";
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
