{
  unify.nixos = {
    pkgs,
    config,
    ...
  }: {
    programs.adb.enable = true;

    users.users.${config.user.username}.extraGroups = ["adbuser"];

    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
    environment.systemPackages = with pkgs; [quickemu];
  };
}
