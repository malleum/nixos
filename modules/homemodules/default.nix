{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./dunst.nix
    ./rofi.nix
    ./spotify.nix
    ./term.nix
    ./tmux.nix
    ./zsh.nix
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  home.packages = map (a: pkgs.callPackage a {}) (lib.filesystem.listFilesRecursive ./scripts);
}
