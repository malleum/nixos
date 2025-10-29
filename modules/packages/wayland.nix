{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      hyprland-qtutils
      hyprpicker
      kdePackages.qtwayland
      swww
      wdisplays
      wl-clipboard
      wlrctl
      wtype
    ];
  };
}
