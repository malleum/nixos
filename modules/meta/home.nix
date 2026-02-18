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
        browser
        ;
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
        mimeApps = {
          enable = true;
          defaultApplications = let
            browserdesktop = "${pkgs.${browser}}/share/applications/${browser}.desktop";
          in {
            "application/pdf" = browserdesktop;
            "image/gif" = browserdesktop;
            "image/jpeg" = browserdesktop;
            "image/png" = browserdesktop;
            "text/html" = browserdesktop;
            "text/plain" = browserdesktop;
            "video/x-matroska" = browserdesktop;
            "x-scheme-handler/about" = browserdesktop;
            "x-scheme-handler/http" = browserdesktop;
            "x-scheme-handler/https" = browserdesktop;
            "x-scheme-handler/unknown" = browserdesktop;
          };
        };
      };
    };

    nixos.home-manager = {
      backupFileExtension = "bak";
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
