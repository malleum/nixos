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
      else indexHelper (builtins.tail l) (i + 1);
  in
    indexHelper list 0;

  colors = [
    "#${config.stylix.base16Scheme.base0A}"
    "#${config.stylix.base16Scheme.base0C}"
    "#${config.stylix.base16Scheme.base0D}"
    "#${config.stylix.base16Scheme.base08}"
  ];

  mods =
    if (config.networking.hostName == "magnus")
    then ["battery" "tray" "pulseaudio" "network" "cpu" "memory" "disk" "clock#c2" "clock" "custom/chron"]
    else ["tray" "pulseaudio" "network" "cpu" "memory" "disk" "battery" "clock#c2" "clock" "custom/chron"];

  modulo' = a: b: a - b * builtins.div a b;
  modulo = a: (modulo' a (builtins.length colors));
  c = lib.attrsets.genAttrs mods (mod: (builtins.elemAt colors (modulo (indexOf mods mod))));

  barSettings = {
    height = 36;
    spacing = 8;
    layer = "top";
    position = "top";
    modules-left = ["${config.wm}/workspaces"];
    modules-right = mods;
    tray.spacing = 10;

    "${config.wm}/workspaces" = {
      format = "{icon}";
      format-icons = {
        "1" = "unu";
        "2" = "du";
        "3" = "tri";
        "4" = "kvar";
        "5" = "kvin";
        "default" = "";
      };
    };

    battery = {
      format = "baterio {capacity}% {icon}";
      format-charging = "baterio {capacity}% 󰂄";
      format-plugged = "baterio {capacity}% 󰂄";
      format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      states.critical = 15;
    };
    clock = {
      interval = 1;
      format = "horloĝo {:%H:%M:%S} 󰥔";
    };
    "clock#c2" = {
      format = "dato {:%m-%d} 󰸗";
    };
    cpu = {
      format = "procesoro {usage}% 󰍛";
    };
    memory = {
      format = "memoro {used:0.1f}G 󰾅";
    };
    disk = {
      format = "disko {percentage_used}% 󰋊";
    };
    network = {
      interval = 1;
      tooltip-format = "{ifname} {ipaddr}/{cidr} |  ^ {bandwidthUpBits}, v {bandwidthDownBits} | {essid}";
      format-disconnected = "reto: malkonektita ⚠";
      format-wifi = "reto {signalStrength}% ";
      format-ethernet = "reto: 󰈀";
      on-click = "nm-connection-editor";
    };
    pulseaudio = {
      format = "aŭdio {volume}% {icon}";
      format-bluetooth = "aŭdio {volume}% {icon} 󰂰";
      format-muted = "aŭdio: mutita 󰝟";
      format-source = "{volume}% ";
      format-source-muted = "";
      on-click = "pavucontrol";
      format-icons = {
        default = ["" "" ""];
      };
    };
    temperature = {
      critical-threshold = 80;
      format = "temperaturo {temperatureC}°C {icon}";
      format-icons = ["󰈸" "󰈸" "󰈸"]; # Using a consistent icon
    };

    # ADDED custom module definition
    "custom/chron" = {
      format = "chrono {} 󱑤";
      exec = "chron";
      interval = 1;
      return-type = "text";
    };
  };
in {
  home-manager.users.joshammer = {
    programs.waybar = {
      enable = true;
      settings."cio" = barSettings;
      style =
        #css
        ''
          * {
            font-family: JetBrainsMono Nerd Font; /* Ensure you have Nerd Font for icons */
            font-size: 15px;
            font-weight: bold;
          }

          window#waybar {
            background: rgba(30, 30, 45, 0.85);
            border-radius: 15px;
            color: #${config.stylix.base16Scheme.base05};
          }

          #workspaces {
            background: #${config.stylix.base16Scheme.base01};
            margin: 5px;
            padding: 0px 5px;
            border-radius: 10px;
            border: 1px solid #${config.stylix.base16Scheme.base03};
          }

          #workspaces button {
            padding: 0px 10px;
            margin: 3px 3px;
            border-radius: 8px;
            color: #${config.stylix.base16Scheme.base04};
            background: transparent;
            transition: all 0.3s ease-in-out;
          }

          #workspaces button:hover {
            background: #${config.stylix.base16Scheme.base02};
            color: #${config.stylix.base16Scheme.base06};
          }

          #workspaces button.active {
            color: #${config.stylix.base16Scheme.base07};
            background-color: ${c.clock};
            padding: 0px 15px;
          }

          #workspaces button.urgent {
            background-color: #${config.stylix.base16Scheme.base08};
            color: #${config.stylix.base16Scheme.base01};
          }

          /* General module styling */
          #clock,
          #clock.c2,
          #battery,
          #cpu,
          #memory,
          #disk,
          #temperature,
          #network,
          #pulseaudio,
          #tray,
          #custom-chron {
            padding: 2px 12px;
            margin: 6px 3px;
            border-radius: 10px;
            background-color: #${config.stylix.base16Scheme.base01};
            color: #${config.stylix.base16Scheme.base06};
            border: 2px solid #${config.stylix.base16Scheme.base02};
            transition: all 0.3s ease-in-out;
          }

          /* Add a hover effect to all modules */
          #clock:hover,
          #clock.c2:hover,
          #battery:hover,
          #cpu:hover,
          #memory:hover,
          #disk:hover,
          #temperature:hover,
          #network:hover,
          #pulseaudio:hover,
          #tray:hover,
          #custom-chron:hover {
             background-color: #${config.stylix.base16Scheme.base02};
             border: 2px solid #${config.stylix.base16Scheme.base04};
          }


          /* Using border for the dynamic color accent */
          #clock { border-left: 5px solid ${c.clock}; }
          #clock.c2 { border-left: 5px solid ${c."clock#c2"}; }
          #battery { border-left: 5px solid ${c.battery}; }
          #cpu { border-left: 5px solid ${c.cpu}; }
          #memory { border-left: 5px solid ${c.memory}; }
          #disk { border-left: 5px solid ${c.disk}; }
          #network { border-left: 5px solid ${c.network}; }
          #pulseaudio { border-left: 5px solid ${c.pulseaudio}; }
          /* #temperature { border-left: 5px solid {c.temperature}; } */
          #tray { border-left: 5px solid ${c.tray}; }
          /* Waybar changes custom/chron to custom-chron in CSS */
          #custom-chron { border-left: 5px solid ${c."custom/chron"}; }


          /* Critical and special states styling */
          @keyframes blink {
            to {
              background-color: #${config.stylix.base16Scheme.base09};
              color: #${config.stylix.base16Scheme.base01};
            }
          }

          #battery.critical:not(.charging) {
            border: 2px solid #${config.stylix.base16Scheme.base08};
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
          }

          #network.disconnected {
            background-color: #${config.stylix.base16Scheme.base08};
            color: #${config.stylix.base16Scheme.base01};
          }

          /*
          #temperature.critical {
            background-color: #${config.stylix.base16Scheme.base08};
            color: #${config.stylix.base16Scheme.base01};
          }
          */
        '';
    };
  };
}
