{
  unify.home = {hostConfig, ...}: let
    mkDirStr = dir: "${hostConfig.user.homeDirectory}/${dir}";
  in {
    xdg.userDirs = {
      enable = true;

      documents = mkDirStr "documents";
      download = mkDirStr "downloads";
    };
  };

  unify.modules.gui.home = {
    pkgs,
    hostConfig,
    ...
  }: {
    xdg = {
      mimeApps = {
        enable = true;
        defaultApplications = let
          inherit (hostConfig.user) browser;
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
}
