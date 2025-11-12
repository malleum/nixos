{
  unify = {
    home = {
      hostConfig,
      lib,
      ...
    }: let
      inherit (hostConfig.user) username homeDirectory configHome browser;
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
        mimeApps.defaultApplications = {
          "text/html" = "${browser}.desktop";
          "x-scheme-handler/http" = "${browser}.desktop";
          "x-scheme-handler/https" = "${browser}.desktop";
        };
      };
    };

    nixos.home-manager = {
      backupFileExtension = "";
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
