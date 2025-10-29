{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      hyprland-qtutils
      hyprpicker
      kdePackages.xwaylandvideobridge
      qt6.qtwayland
      swww
      wdisplays
      wl-clipboard
      wlrctl
      wtype
    ];
  };
}
