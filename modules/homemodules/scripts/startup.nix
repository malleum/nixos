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
  
  wl-paste --type text --watch cliphist store &
  wl-paste --type image --watch cliphist store &
  wl-clip-persist --clipboard regular &

  onedrive --monitor &
  nm-applet &
''
