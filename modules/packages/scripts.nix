{
  unify.home =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = map (a: pkgs.callPackage a { }) (lib.filesystem.listFilesRecursive ../scripts);
    };
}
