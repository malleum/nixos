{
  flake.modules.homeManager.gui = {pkgs, ...}: {
    home.packages = with pkgs; [
      hyprpicker
      kdePackages.qtwayland
      awww
      wdisplays
      wl-clipboard
      wlrctl
      wtype
    ];
  };
}
