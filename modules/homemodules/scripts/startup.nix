{
  pkgs,
  wallpaper ? "/home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg",
  ...
}:
pkgs.writeShellScriptBin "startup" ''

  killall .waybar-wrapped
  waybar &
  swww-daemon &
  swww img ${wallpaper}
  
  wl-paste --watch cliphist store &

  onedrive --monitor &
  nm-applet &
  vesktop &
''
