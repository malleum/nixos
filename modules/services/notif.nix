{
  unify.modules.gui.home = {
    lib,
    hostConfig,
    pkgs,
    ...
  }: {
    home.packages = [pkgs.sound-theme-freedesktop];
    services.swaync = {
      enable = true;

      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        timeout = 4;
        timeout-low = 2;
        timeout-critical = 10;
        notification-icon-size = 48;
        notification-window-preferred-output =
          if hostConfig.name == "magnus"
          then "HDMI-A-1"
          else "eDP-1";
        control-center-preferred-output =
          if hostConfig.name == "magnus"
          then "HDMI-A-1"
          else "eDP-1";

        scripts = {
          message-sound = {
            exec = "${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/window-attention.oga";
            app-name = "^iamb$";
          };
        };
      };

      # Appended after stylix's base16 stylesheet (mkAfter), so these rules
      # cascade last and can reuse the @baseXX colors stylix already defines.
      # Matches the bar: rounded corners, subtle border, red accent on critical.
      style = lib.mkAfter ''
        .notification-row {
          margin: 4px 8px;
        }

        /* Push the floating popup stack below the bar (height 32) so it
           doesn't cover the clock. Only the first row needs the top gap. */
        .floating-notifications .notification-row:first-child {
          margin-top: 44px;
        }

        /* Single filled rounded card. Fill the bg here so there's no
           transparent ring (the old padding showed the transparent
           .notification-background behind it). */
        .notification {
          padding: 0;
          border-radius: 14px;
          border: 2px solid @base02;
          background: @base00;
        }

        .notification.critical {
          border-color: @base08;
        }

        /* Wrapper: transparent passthrough, no padding (padding here would
           re-open a transparent ring around the card). */
        .control-center .notification-row .notification-background,
        .floating-notifications.background .notification-row .notification-background {
          background: transparent;
          border: none;
          padding: 0;
        }

        /* Innermost: kill stylix's 1px border + bg, hold the real padding. */
        .notification-content {
          background: transparent;
          border: none;
          padding: 8px;
          border-radius: 14px;
        }

        .notification .summary,
        .notification .title {
          font-weight: bold;
          color: @base05;
        }

        .notification .body {
          color: @base05;
        }

        .control-center {
          border-radius: 14px;
          border: 2px solid @base02;
        }

        .close-button {
          border-radius: 999px;
          margin: 6px;
        }
      '';
    };
  };
}
