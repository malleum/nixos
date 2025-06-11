{
  config,
  lib,
  pkgs,
  ...
}: let
  indexOf = list: item: let
    indexHelper = l: i:
      if l == []
      then -1
      else if builtins.elemAt l 0 == item
      then i
      else indexHelper (builtins.tail l) (i + 1); # Recurse with the next index and tail of the list
  in
    indexHelper list 0;

  colors = [
    "#${config.stylix.base16Scheme.base09}"
    "#${config.stylix.base16Scheme.base0A}"
    "#${config.stylix.base16Scheme.base0B}"
    "#${config.stylix.base16Scheme.base0C}"
  ];

  mods =
    if (config.networking.hostName == "magnus")
    then ["battery" "tray" "pulseaudio" "network" "cpu" "temperature" "disk" "date2" "date" "chron"]
    else ["tray" "pulseaudio" "network" "cpu" "temperature" "disk" "battery" "date2" "date" "chron"];
  modulo' = a: b: a - b * builtins.div a b;
  modulo = a: (modulo' a (builtins.length colors));
  c = lib.attrsets.genAttrs mods (mod: (builtins.elemAt colors (modulo (indexOf mods mod))));
in {
  home-manager.users.joshammer.services.polybar = lib.mkIf config.i3.enable {
    enable = true;
    package = pkgs.polybar; # Ensure polybar is available
    script = "polybar main &"; # Launch the bar named 'main'
    config = {
      "bar/main" = {
        width = "100%";
        height = 30;
        offset-x = 0;
        offset-y = 0;
        radius = 0;
        position = "top";
        layer = "top";
        padding-left = 1;
        padding-right = 1;
        module-margin = 1;
        background = "transparent";
        foreground = "#ffffff";
        font-0 = "JetBrainsMono:size=13;2";
        tray-position = "left";
        tray-padding = 10;
        tray-background = "${c.tray}";
        modules-left = "i3";
        modules-center = (
          if (config.networking.hostName == "magnus")
          then builtins.concatStringsSep " " mods
          else ""
        );
        modules-right = (
          if (config.networking.hostName != "magnus")
          then builtins.concatStringsSep " " mods
          else ""
        );
      };
      "module/i3" = {
        type = "internal/i3";
        format = "<label-state>";
        label-focused = "%icon%";
        label-unfocused = "%icon%";
        label-urgent = "%icon%";
        label-focused-foreground = "#000000";
        label-focused-background = "${c.date}";
        label-focused-padding = 2;
        label-unfocused-foreground = "#ffffff";
        label-unfocused-background = "${c.chron}";
        label-unfocused-padding = 2;
        label-urgent-foreground = "${c.temperature}";
        label-urgent-padding = 2;
        strip-workspace-numbers = false;
        index-sort = true;
        format-icons = ["𝋁" "𝋂" "𝋃" "𝋄" "𝋅"];
      };
      "module/backlight" = {
        type = "internal/backlight";
        format = "<label>";
        label = "%percentage%% %icon%";
        format-icons = ["" ""];
      };
      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0"; # Adjust to your battery name (check with 'ls /sys/class/power_supply/')
        adapter = "AC"; # Adjust to your adapter name
        format-charging = "<label-charging>";
        label-charging = "%percentage%% ";
        format-discharging = "<label-discharging>";
        label-discharging = "%percentage%% %icon%";
        format-full = "<label-full>";
        label-full = "%percentage%% ";
        format-icons = ["" "" "" "" ""];
        ramp-capacity-0 = 7; # Critical state
        ramp-capacity-1 = 15; # Warning state
        format-discharging-foreground = "#000000";
        format-discharging-background = "${c.battery}";
        format-charging-foreground = "#ffffff";
        format-charging-background = "${c.battery}";
        format-full-foreground = "#ffffff";
        format-full-background = "${c.battery}";
        animation-charging-0 = "%percentage%% ";
        animation-discharging-0 = "%percentage%% %icon%";
        animation-discharging-1 = "%percentage%% %icon%";
        animation-discharging-foreground = "#ffffff";
        animation-discharging-background = "#f53c3c";
        animation-discharging-framerate = 500; # 0.5s blink
      };
      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%H:%M:%S";
        format = "<label>";
        label = "%date%";
        label-foreground = "#000000";
        label-background = "${c.date}";
        label-padding = 2;
      };
      "module/date2" = {
        type = "internal/date";
        interval = 1;
        date = "%m-%d";
        format = "<label>";
        label = "%date%";
        label-foreground = "#000000";
        label-background = "${c.date2}";
        label-padding = 2;
      };
      "module/chron" = {
        type = "custom/script";
        exec = "chron"; # Assumes 'chron' is in your PATH
        interval = 1;
        format = "<label>";
        label = "%output%";
        label-foreground = "#000000";
        label-background = "${c.chron}";
        label-padding = 2;
      };
      "module/cpu" = {
        type = "internal/cpu";
        interval = 1;
        format = "<label>";
        label = "%percentage%% ";
        label-foreground = "#000000";
        label-background = "${c.cpu}";
        label-padding = 2;
      };
      "module/disk" = {
        type = "internal/disk";
        path = "/";
        interval = 1;
        format = "<label>";
        label = "%percentage_used%% ⬤";
        label-foreground = "#000000";
        label-background = "${c.disk}";
        label-padding = 2;
      };
      "module/network" = {
        type = "internal/network";
        interface = "wlan0"; # Adjust to your interface (check with 'ip link')
        interval = 1;
        format-connected = "<label-connected>";
        label-connected = "%signal%% ";
        format-disconnected = "<label-disconnected>";
        label-disconnected = "⚠";
        label-disconnected-foreground = "#ffffff";
        label-disconnected-background = "#f53c3c";
        format-connected-foreground = "#000000";
        format-connected-background = "${c.network}";
        label-connected-padding = 2;
        format-packetloss = "<label-packetloss>";
        label-packetloss = "%ifname% (No IP)";
        click-left = "nm-connection-editor";
      };
      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<label-volume>";
        label-volume = "%percentage%% %icon% %name%";
        format-volume-foreground = "#000000";
        format-volume-background = "${c.pulseaudio}";
        label-volume-padding = 2;
        format-muted = "<label-muted>";
        label-muted = " %name%";
        label-muted-foreground = "#${config.stylix.base16Scheme.base07}";
        label-muted-background = "#${config.stylix.base16Scheme.base01}";
        label-muted-padding = 2;
        click-right = "pavucontrol";
        ramp-volume-0 = "";
        ramp-volume-1 = "";
        ramp-volume-2 = "";
        ramp-headphones-0 = "";
      };
      "module/temperature" = {
        type = "internal/temperature";
        interval = 1;
        thermal-zone = 0; # Adjust to your thermal zone (check /sys/class/thermal/thermal_zone*)
        warn-temperature = 80;
        format = "<label>";
        label = "%temperature-c%°C %icon%";
        label-foreground = "#000000";
        label-background = "${c.temperature}";
        label-padding = 2;
        format-warn = "<label-warn>";
        label-warn = "%temperature-c%°C %icon%";
        label-warn-foreground = "#000000";
        label-warn-background = "#eb4d4b";
        label-warn-padding = 2;
        ramp-0 = "";
        ramp-1 = "";
        ramp-2 = "";
      };
      "module/tray" = {
        type = "internal/tray";
        tray-spacing = 10;
        tray-background = "${c.tray}";
        tray-foreground = "#000000";
        tray-padding = 2;
      };
    };
  };
}
