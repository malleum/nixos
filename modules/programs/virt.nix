{
  flake.modules.homeManager.vrt = {pkgs, ...}: {
    home.packages = with pkgs; [
      nixos-shell
      quickemu
      qemu
      android-tools
    ];
  };
}
