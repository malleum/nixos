{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./dunst.nix
    ./rofi.nix
    ./term.nix
    ./tmux.nix
    ./sh.nix
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  programs = {
    spotify-player = {
      enable = true;
      settings = {
        client_id_command = {
          command = "cat";
          args = ["${config.home.homeDirectory}/documents/gh/k/spotify_id"];
        };
      };
    };
    vesktop = {
      enable = true;
    };
  };

  home.packages = map (a: pkgs.callPackage a {}) (lib.filesystem.listFilesRecursive ./scripts);
}
