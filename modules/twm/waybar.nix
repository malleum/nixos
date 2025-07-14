{
  config,
  lib,
  ...
}: let
  monitorNames = ["eDP-1" "HDMI-A-1"]; # e.g., ["DP-1", "HDMI-A-1"]
  primaryMonitor = "eDP-1";
  secondaryMonitors = lib.lists.filter (m: m != primaryMonitor) monitorNames;

  indexOf = list: item: let
    indexHelper = l: i:
      if l == []
      then -1
      else if builtins.elemAt l 0 == item
      then i
      else indexHelper (builtins.tail l) (i + 1);
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
    then ["battery" "tray" "pulseaudio" "network" "cpu" "temperature" "disk" "clock#c2" "clock"]
    else ["tray" "pulseaudio" "network" "cpu" "temperature" "disk" "battery" "clock#c2" "clock"];
  modulo' = a: b: a - b * builtins.div a b;
  modulo = a: (modulo' a (builtins.length colors));
  c = lib.attrsets.genAttrs mods (mod: (builtins.elemAt colors (modulo (indexOf mods mod))));

  # Define the settings for a SINGLE bar. We will reuse this.
  barSettings = {
    height = 30;
    spacing = 6;
    layer = "top";
    position = "top";
    modules-left = ["${config.wm}/workspaces"];
    modules-center =
      if (config.networking.hostName == "magnus")
      then mods
      else [];
    modules-right =
      if (config.networking.hostName != "magnus")
      then mods
      else [];

    # Module definitions are unchanged
    tray.spacing = 10;
    "${config.wm}/workspaces" = {
      format = "{icon}";
      format-icons = {
        "1" = "𝋁";
        "2" = "𝋂";
        "3" = "𝋃";
        "4" = "𝋄";
        "5" = "𝋅";
      };
    };
    battery = {
      format = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-icons = ["" "" "" "" ""];
      states.critical = 7;
    };
    clock = {
      interval = 1;
      format = "{:%H:%M:%S}";
    };
    "clock#c2".format = "{:%m-%d}";
    cpu.format = "{usage}% ";
    memory.format = "{}% ";
    disk.format = "{percentage_used}% ⬤";
    network = {
      interval = 1;
      tooltip-format = "{ifname}: {ipaddr}/{cidr} |  ^ {bandwidthUpBits}, v {bandwidthDownBits} | {essid}";
      format-disconnected = "⚠";
      format-wifi = "{signalStrength} ";
      on-click = "nm-connection-editor";
    };
    pulseaudio = {
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon}  {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      on-click = "pavucontrol";
    };
    temperature = {
      critical-threshold = 80;
      format = "{temperatureC}°C {icon}";
      format-icons = ["" "" ""];
    };
  };
in {
  # This configures Waybar for Home Manager
  home-manager.users.joshammer = {
    programs.waybar = {
      enable = true;
      # The default config now explicitly creates a bar for each monitor.
      settings = lib.lists.map (name: barSettings // {output = name;}) monitorNames;
      # Your entire style section is unchanged.
      style =
        #css
        ''
          * {
              font-family: JetBrainsMono;
              font-size: 16px;
          }

          window#waybar {
              color: #ffffff;
              background: transparent;
          }

          /* ... all your other CSS ... */
          #workspaces  {
              margin: 0 4px;
              color: ${c.temperature};
              border-bottom: none;
          }

          #workspaces button {
              padding: 0 3px;
              margin: 0 5px;
              border-radius: 0;
              color: #ffffff;
              border-bottom: none;
              padding: 0 10px;
              border-radius: 6px;
              background-color: ${c."pulseaudio"};
          }

          #workspaces button.active {
              color: #000000;
              border-bottom: none;
              background-color: ${c.clock};
          }

          #workspaces button.urgent {
              color: ${c.temperature};
              border-bottom: none;
          }

          #clock,
          #battery,
          #cpu,
          #memory,
          #disk,
          #temperature,
          #backlight,
          #network,
          #pulseaudio,
          #wireplumber,
          #tray {
              padding: 0 10px;
              border-radius: 6px;
          }

          #clock {
              background-color: ${c.clock};
              color: #000000;
          }

          #clock.c2 {
              background-color: ${c."clock#c2"};
          }

          #battery {
              background-color: ${c.battery};
              color: #000000;
          }

          #battery.charging, #battery.plugged {
              color: #ffffff;
              background-color: ${c.battery};
          }

          @keyframes blink {
              to {
                  background-color: #ffffff;
                  color: #000000;
              }
          }

          #battery.critical:not(.charging) {
              background-color: #f53c3c;
              color: #ffffff;
              animation-name: blink;
              animation-duration: 0.5s;
              animation-timing-function: linear;
              animation-iteration-count: infinite;
              animation-direction: alternate;
          }

          #cpu {
              background-color: ${c.cpu};
              color: #000000;
          }

          #disk {
              background-color: ${c.disk};
              color: #000000;
          }

          #network {
              background-color: ${c.network};
              color: #000000;
          }

          #network.disconnected {
              background-color: #f53c3c;
          }

          #pulseaudio {
              background-color: ${c.pulseaudio};
              color: #000000;
          }

          #pulseaudio.muted {
              background-color: #${config.stylix.base16Scheme.base01};
              color: #${config.stylix.base16Scheme.base07};
          }

          #temperature {
              background-color: ${c.temperature};
              color: #000000;
          }

          #temperature.critical {
              background-color: #eb4d4b;
          }

          #tray {
              background-color: ${c.tray};
              color: #000000;
          }

          #tray > .passive {
              -gtk-icon-effect: dim;
          }

          #tray > .needs-attention {
              -gtk-icon-effect: highlight;
              background-color: #eb4d4b;
          }
        '';
    };

    # This creates the *second* config file for our script to use.
    # It generates a config with bars only on the secondary monitors.
    home.file.".config/waybar/secondary-only.jsonc" = {
      text = builtins.toJSON (lib.lists.map (name: barSettings // {output = name;}) secondaryMonitors);
    };
  };
}
