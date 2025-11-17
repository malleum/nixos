{
  unify.home =
    { hostConfig, ... }:
    let
      mkDirStr = dir: "${hostConfig.user.homeDirectory}/${dir}";
    in
    {
      xdg.userDirs = {
        enable = true;

        documents = mkDirStr "documents";
        download = mkDirStr "downloads";
      };
    };
}
