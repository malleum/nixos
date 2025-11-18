{
  unify.nixos = {hostConfig, ...}: {
    programs.adb.enable = true;
    virtualisation.virtualbox.host = {
      enable = true;
      # enableKvm = true;
    };

    users.users.${hostConfig.user.username}.extraGroups = ["adbuser" "vboxusers"];
  };

  unify.home = {pkgs, ...}: {
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
    home.packages = with pkgs; [
      nixos-shell
      quickemu
      vagrant
    ];
  };
}
