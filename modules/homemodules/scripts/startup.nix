{
  pkgs,
  wallpaper ? "/home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg",
  ...
}: let
  rg = "${pkgs.ripgrep}/bin/rg";
in
  pkgs.writeShellScriptBin "startup" ''

    if ! [[ $(ps -e | ${rg} -i "discord") ]]; then
      vesktop &
      # discord &
    fi

    onedrive --monitor &
    nm-applet &

    if [[ $(ps -e | ${rg} "X" | ${rg} -v "wayland") ]]; then # Xorg

      feh --bg-fill ${wallpaper}
      start-polybar
      if [[ $(hostname) == "magnus" ]]; then
        xrandr --output DisplayPort-0 --off --output DisplayPort-1 --mode 1920x1080 --rate 165.00 --pos 2922x0 --rotate normal --output DisplayPort-2 --off --output HDMI-A-0 --mode 1920x1080 --pos 0x0 --rotate normal
      fi

    else # hypr

      killall .waybar-wrapped
      waybar &
      if [[ $(echo ${wallpaper} | ${rg} '(.mp4)|(.gif)') ]]; then
        ${pkgs.mpvpaper}/bin/mpvpaper '*' ${wallpaper} &
      else
        swww-daemon &
        swww img ${wallpaper}
      fi

      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      wl-paste --type text --watch cliphist store
      wl-paste --type image --watch cliphist store

      export XDG_CURRENT_DESKTOP="Hyprland";
      export XDG_SESSION_DESKTOP="Hyprland";
      export XDG_SESSION_TYPE="wayland";
    fi
  ''
