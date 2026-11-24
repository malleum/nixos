{
  flake.modules.homeManager.gui = {pkgs, ...}: {
    home.packages = with pkgs; [
      hyprpicker
      kdePackages.qtwayland
      wdisplays
      wl-clipboard
      wlrctl
      wtype
    ];
  };
}
