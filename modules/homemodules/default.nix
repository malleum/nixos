{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./dunst.nix
    ./fish.nix
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

  services = {
    flameshot = {
      enable = true;
      settings.General.showStartupLaunchMessage = false;
    };
  };

  home.packages =
    (map (a: pkgs.callPackage (./scripts + "/${a}.nix") {}) ["chron" "kls" "start-polybar"])
    ++ [(pkgs.callPackage ./scripts/startup.nix {wallpaper = "${config.stylix.image}";})];
}
