{pkgs, ...}: let
  lib = pkgs.lib;
in
  pkgs.mkShell {
    packages = map (a: pkgs.callPackage a {}) (lib.filesystem.listFilesRecursive ./scripts);
  }
