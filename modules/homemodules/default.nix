{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./dunst.nix
    ./zsh.nix
    ./rofi.nix
    ./term.nix
    ./tmux.nix
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  home.packages = map (a: pkgs.callPackage a {}) (lib.filesystem.listFilesRecursive ./scripts);
}
