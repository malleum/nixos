{
  unify.nixos = {pkgs, ...}: {
    programs.adb.enable = true;

    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
    environment.systemPackages = with pkgs; [quickemu];
  };
}
