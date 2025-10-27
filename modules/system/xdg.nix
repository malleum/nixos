{
  unify.home = {hostConfig, ...}: let
    mkDirStr = dir: "${hostConfig.home.homeDirectory}/${dir}";
  in {
    xdg.userDirs = {
      enable = true;

      documents = mkDirStr "documents";
      download = mkDirStr "downloads";
    };
  };
}
