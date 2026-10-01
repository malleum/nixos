{
  flake.modules.homeManager.med = {pkgs, ...}: {
    home.packages = with pkgs; [
      gimp
      losslesscut-bin
      vlc
    ];
  };
}
