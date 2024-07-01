{
  config,
  lib,
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

  mods = ["tray" "pulseaudio" "network" "cpu" "memory" "temperature" "disk" "backlight" "battery" "clock#c2" "clock" "custom/mt"];
  modulo' = a: b: a - b * builtins.div a b;
  modulo = a: (modulo' a (builtins.length colors));
  c = lib.attrsets.genAttrs mods (mod: (builtins.elemAt colors (modulo (indexOf mods mod))));
in {
  programs.waybar = {
    enable = true;
    # https://github.com/georgewhewell/nixos-host/blob/master/home/waybar.nix
    settings = [
      {
        height = 30;
        spacing = 6;
        tray.spacing = 10;
        layer = "top";
        position = "top";
        modules-center = [];
        modules-left = ["hyprland/workspaces"];
        modules-right = mods;
        backlight = {
          format = "{percent}% {icon}";
          format-icons = ["" ""];
        };
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
          };
          # persistent-workspaces."*" = 5;
        };
        battery = {
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-icons = ["" "" "" "" ""];
          format-plugged = "{capacity}% ";
          states = {
            critical = 7;
            warning = 15;
          };
        };
        clock = {
          interval = 1;
          format = "{:%H:%M:%S}";
        };
        "clock#c2".format = "{:%m-%d}";
        "custom/mt" = {
          interval = 1;
          exec = "chron";
          format = "{}";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory.format = "{}% ";
        disk.format = "{percentage_used}% ⬤";
        network = {
          interval = 1;
          tooltip-format = "{ifname}: {ipaddr}/{cidr} |  ^ {bandwidthUpBits}, v {bandwidthDownBits} | {essid}";
          format-disconnected = "⚠";
          format-ethernet = "{signalStrength} ";
          format-wifi = "{signalStrength} ";
          format-linked = "{ifname} (No IP)";
          on-click = "nm-connection-editor";
        };
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon}  {format_source}";
          format-bluetooth-muted = " {icon}  {format_source}";
          format-icons = {
            car = "";
            default = ["" "" ""];
            handsfree = "";
            headphones = "";
            headset = "";
            phone = "";
            portable = "";
          };
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
      }
    ];
    style = ''
      * {
          font-family: JetBrainsMono;
          font-size: 13px;
      }

      window#waybar {
          color: #ffffff;
          background: transparent;
          border-bottom: none
      }

      #workspaces  {
          margin: 0 4px;
          color: ${c.temperature};
          border-bottom: none
      }

      #workspaces button {
          padding: 0 3px;
          margin: 0 5px;
          border-radius: 0;
          color: #ffffff;
          border-bottom: none
      }

      .modules-left #workspaces button.active {
          color: ${c."custom/mt"};
          border-bottom: none
      }

      #workspaces button.urgent {
          color: ${c.temperature};
          border-bottom: none
      }

      #clock,
      #custom-mt,
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

      #custom-mt {
          background-color: ${c."custom/mt"};
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

      #memory {
          background-color: ${c.memory};
          color: #000000;
      }

      #disk {
          background-color: ${c.disk};
          color: #000000;
      }

      #backlight {
          background-color: ${c.backlight};
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
}
