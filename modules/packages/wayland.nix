{
  flake.modules.homeManager.gui = {pkgs, ...}: {
    home.packages = with pkgs; [
      hyprland-qtutils
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
