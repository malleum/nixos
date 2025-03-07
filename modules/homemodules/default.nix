{
  pkgs,
  lib,
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

  programs.spotify-player = {
    enable = true;
    settings.client_id_command = "~/OneDrive/Documents/Stuff/ProgrammingOrCodes/psswd/spotify_id.sh";
  };

  home.packages = map (a: pkgs.callPackage a {}) (lib.filesystem.listFilesRecursive ./scripts);
}
