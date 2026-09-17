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

  unify.modules.gui.home = {hostConfig, ...}: {
    xdg = {
      # Opening a folder drops into a terminal there. foot has no directory
      # argument of its own, so wrap it in a hidden entry.
      desktopEntries.foot-dir = {
        name = "Terminal Here";
        exec = "foot -D %f";
        mimeType = ["inode/directory"];
        noDisplay = true;
      };

      mimeApps = {
        enable = true;
        # Desktop IDs, not store paths: gio/electron/portals only resolve IDs
        # and otherwise fall back to mimeinfo.cache (where brave sorts first).
        defaultApplications = let
          browser = "${hostConfig.user.browser}.desktop";
        in {
          "inode/directory" = "foot-dir.desktop";

          "application/pdf" = browser;
          "application/rdf+xml" = browser;
          "application/rss+xml" = browser;
          "application/xhtml+xml" = browser;
          "application/xhtml_xml" = browser;
          "application/xml" = browser;
          "image/gif" = browser;
          "image/jpeg" = browser;
          "image/png" = browser;
          "image/webp" = browser;
          "text/html" = browser;
          "text/plain" = browser;
          "text/xml" = browser;
          "video/x-matroska" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/chromium" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/unknown" = browser;
        };
      };
    };
  };
}
