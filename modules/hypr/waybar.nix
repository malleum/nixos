{config, ...}: {
  programs.waybar = {
    enable = true;
    # https://github.com/georgewhewell/nixos-host/blob/master/home/waybar.nix
    settings = [
      {
        height = 30;
        spacing = 6;
        tray = {spacing = 10;};
        layer = "top";
        position = "top";
        modules-center = [];
        modules-left = ["hyprland/workspaces" "sway/workspaces"];
        modules-right = [
          "tray"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "disk"
          "backlight"
          "battery"
          "clock#c2"
          "clock"
          "custom/mt"
        ];
        battery = {
          format = "{capacity}% {icon}";
          format-alt = "{time} {icon}";
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
        "clock#c2" = {format = "{:%m-%d}";};
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
        disk.format = "{}% ⬤";
        network = {
          interval = 1;
          tooltip-format = "{ifname}: {ipaddr}/{cidr} |  ^ {bandwidthUpBits}, v {bandwidthDownBits}";
          format-disconnected = "Disconnected ⚠";
          format-ethernet = "{ifname}: {ipaddr}/{cidr}";
          format-linked = "{ifname} (No IP)";
          format-wifi = "{essid} {signalStrength} ";
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
    style = let
      b9 = "#${config.stylix.base16Scheme.base09}";
      ba = "#${config.stylix.base16Scheme.base0A}";
      bb = "#${config.stylix.base16Scheme.base0B}";
      bc = "#${config.stylix.base16Scheme.base0C}";
    in ''
      * {
          font-family: JetBrainsMono;
          font-size: 13px;
      }

      window#waybar {
          background-color: rgba(43, 48, 59, 0.5);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
          background: transparent;
          border-bottom: none;
      }

      window#waybar.hidden {
          opacity: 0.2;
      }

      button {
          transition: transform 0.1s ease-in-out;
          background: rgba(0, 0, 0, 0.2);
      }

      button.active {
          border-color: ${b9};
      }

      #workspaces button {
          padding: 0 3px;
          margin: 0 5px;
          color: #ffffff;
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

      #window,
      #workspaces {
          margin: 0 4px;
      }

      .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
      }

      .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
      }

      #clock {
          background-color: ${ba};
          color: #000000;
      }

      #custom-mt {
          background-color: ${bb};
          color: #000000;
      }

      #clock.c2 {
          background-color: ${b9};
      }

      #battery {
          background-color: ${bc};
          color: #000000;
      }

      #battery.charging, #battery.plugged {
          color: #ffffff;
          background-color: ${bc};
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

      label:focus {
          background-color: #000000;
      }

      #cpu {
          background-color: ${bc};
          color: #000000;
      }

      #memory {
          background-color: ${b9};
          color: #000000;
      }

      #disk {
          background-color: ${bb};
          color: #000000;
      }

      #backlight {
          background-color: ${bc};
          color: #000000;
      }

      #network {
          background-color: ${bb};
          color: #000000;
      }

      #network.disconnected {
          background-color: #f53c3c;
      }

      #pulseaudio {
          background-color: ${ba};
          color: #000000;
      }

      #pulseaudio.muted {
          background-color: #${config.stylix.base16Scheme.base01};
          color: #${config.stylix.base16Scheme.base07};
      }

      #wireplumber {
          background-color: ${ba};
          color: #000000;
      }

      #wireplumber.muted {
          background-color: #${config.stylix.base16Scheme.base01};
          color: #${config.stylix.base16Scheme.base07};
      }

      #temperature {
          background-color: ${ba};
          color: #000000;
      }

      #temperature.critical {
          background-color: #eb4d4b;
      }

      #tray {
          background-color: ${b9};
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
