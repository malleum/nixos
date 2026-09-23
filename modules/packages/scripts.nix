{
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    scriptFiles = lib.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive ../scripts);
    nameFromPath = path: lib.removeSuffix ".nix" (lib.removePrefix "_" (baseNameOf (toString path)));
  in {
    packages = builtins.listToAttrs (map (path: {
        name = nameFromPath path;
        value = pkgs.callPackage path {};
      })
      scriptFiles);

    # Unit tests for the time conversions behind duod, chron and jay-status.
    checks.daytime = pkgs.runCommandCC "daytime-tests" {nativeBuildInputs = [pkgs.rustc];} ''
      rustc --edition 2021 --test ${../scripts/_daytime.rs} -o tests
      ./tests
      touch $out
    '';
  };

  unify.home = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = map (a: pkgs.callPackage a {}) (
      lib.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive ../scripts)
    );
  };
}
