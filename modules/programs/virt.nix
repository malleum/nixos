{
  unify.modules.vrt.nixos = {hostConfig, ...}: {
    virtualisation.virtualbox.host = {enable = true;};

    users.users.${hostConfig.user.username}.extraGroups = ["adbuser" "vboxusers"];
  };

  unify.modules.vrt.home = {pkgs, ...}: {
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
    home.packages = with pkgs; [
      nixos-shell
      quickemu
    ];
  };
}
