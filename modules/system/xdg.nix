{
  unify.home = {config, ...}: let
    mkDirStr = dir: "${config.home.homeDirectory}/${dir}";
  in {
    xdg.userDirs = {
      enable = true;

      documents = mkDirStr "documents";
      download = mkDirStr "downloads";
    };
  };
}
