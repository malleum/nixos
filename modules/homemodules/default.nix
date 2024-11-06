{pkgs, ...}: {
  imports = [
    ./dunst.nix
    ./shell.nix
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

  home.packages = map (a: pkgs.callPackage (./scripts + "/${a}.nix") {}) ["chron" "kls"];
}
