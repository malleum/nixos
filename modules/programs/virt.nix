{
  flake.modules.nixos.vrt = {hostConfig, ...}: {
    # virtualisation.virtualbox.host = {enable = true;};

    users.users.${hostConfig.user.username}.extraGroups = [
      # "vboxusers"
    ];
  };

  flake.modules.homeManager.vrt = {pkgs, ...}: {
    # dconf.settings = {
    #   "org/virt-manager/virt-manager/connections" = {
    #     autoconnect = ["qemu:///system"];
    #     uris = ["qemu:///system"];
    #   };
    # };
    home.packages = with pkgs; [
      nixos-shell
      quickemu
      qemu
      android-tools
    ];
  };
}
