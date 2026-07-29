{
  unify.modules.med.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      gimp
      losslesscut-bin
      vlc
    ];
  };
}
