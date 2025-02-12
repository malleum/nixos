{pkgs, ...}: {
  config = {
    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      wrapperFeatures.gtk = true;
    };

    home-manager.users.joshammer.wayland.windowManager.sway = {
      enable = true;
      config = {
        modifier = "Mod4";
        window = {
          titlebar = false;
        };
        input."*" = {
          xkb_layout = "us,us";
          xkb_variant = "dvorak,";
          xkb_options = "caps:escape";
          repeat_delay = "225";
          repeat_rate = "50";
          tap = "enabled";
          natural_scroll = "enabled";
        };
        bars = [];
        seat."*" = {
          hide_cursor = "when-typing enable";
        };
        startup = [
          {command = "waybar";}
          {command = "wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";}
          {command = "vesktop";}
          {command = "nm-applet";}
          {command = "spotify_player -d";}
          {command = "onedrive --monitor";}
        ];
      };
    };
  };
}
