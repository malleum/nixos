{
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages = let
      scriptFiles = lib.filesystem.listFilesRecursive ../scripts;
      nameFromPath = path: let
        base = baseNameOf (toString path);
      in
        lib.removeSuffix ".nix" (lib.removePrefix "_" base);
    in
      builtins.listToAttrs (map (path: {
          name = nameFromPath path;
          value = pkgs.callPackage path {};
        })
        scriptFiles);
  };

  unify.home = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = map (a: pkgs.callPackage a {}) (lib.filesystem.listFilesRecursive ../scripts);
  };
}
