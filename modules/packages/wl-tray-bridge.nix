{
  unify.modules.gui.home = {pkgs, ...}: let
    wl-tray-bridge = let
      src = pkgs.fetchFromGitHub {
        owner = "mahkoh";
        repo = "wl-tray-bridge";
        rev = "04cb349720f266917b5490e4a02f08d6ddf3f233";
        hash = "sha256-pYmFEqMMEsSTYBwxbD2l2F+lO7WuVt1FFmnkCCoaXf0=";
      };
    in
      pkgs.rustPlatform.buildRustPackage {
        pname = "wl-tray-bridge";
        version = "0-unstable-2025-04-01";
        inherit src;
        cargoDeps = pkgs.rustPlatform.importCargoLock {lockFile = "${src}/Cargo.lock";};
        nativeBuildInputs = with pkgs; [pkg-config];
        buildInputs = with pkgs; [pango cairo glib];
      };
  in {
    home.packages = [wl-tray-bridge];
  };
}
