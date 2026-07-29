# wl-tray-bridge. jay implements jay_tray_v1; nm-applet and pasystray speak the
# StatusNotifier DBus protocol. This bridges the two.
#
# Pinned to master -- upstream has no tags. 04cb349 is still current master as
# of 2026-07-29. The version string previously read 0-unstable-2025-04-01,
# which was the date the pin was added here, not the date of the commit
# (2026-02-16).
{pkgs}: let
  src = pkgs.fetchFromGitHub {
    owner = "mahkoh";
    repo = "wl-tray-bridge";
    rev = "04cb349720f266917b5490e4a02f08d6ddf3f233";
    hash = "sha256-pYmFEqMMEsSTYBwxbD2l2F+lO7WuVt1FFmnkCCoaXf0=";
  };
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "wl-tray-bridge";
    version = "0-unstable-2026-02-16";
    inherit src;
    cargoDeps = pkgs.rustPlatform.importCargoLock {lockFile = "${src}/Cargo.lock";};
    nativeBuildInputs = with pkgs; [pkg-config autoPatchelfHook];
    buildInputs = with pkgs; [pango cairo glib wayland];
    runtimeDependencies = with pkgs; [wayland];
  }
