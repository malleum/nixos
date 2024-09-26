{
  pkgs,
  wallpaper ? "/home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg",
  ...
}:
pkgs.writeShellScriptBin "startup" ''

  killall .waybar-wrapped
  waybar &
  ${pkgs.swww}/bin/swww-daemon &
  ${pkgs.swww}/bin/swww img ${wallpaper}
  
  wl-paste --watch ${pkgs.cliphist}/bin/cliphist store &

  onedrive --monitor &
  nm-applet &
  vesktop &
''
