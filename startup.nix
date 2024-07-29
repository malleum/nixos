{
  pkgs,
  wallpaper ? "/home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg", # use cybertruckLego.jpg unless wallpaper is passed into the attribute set
  ...
}: pkgs.writeShellScriptBin "startup" ''

  # network manager
  nm-applet &

  # hyprland stuff
  killall .waybar-wrapped # make sure waybar is dead before starting it
  waybar &

  # wallpaper stuff
  swww-daemon &
  swww img ${wallpaper}

  # setup clipboard to work with both images and text
  wl-paste --type text --watch cliphist store
  wl-paste --type image --watch cliphist store

  # and some env vars to make sure everyone knows we are running wayland server and hyprland specificially
  export XDG_CURRENT_DESKTOP="Hyprland";
  export XDG_SESSION_DESKTOP="Hyprland";
  export XDG_SESSION_TYPE="wayland";
''
