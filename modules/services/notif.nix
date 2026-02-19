{
  unify.modules.gui.home = {
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
        monitor =
          if hostConfig.name == "magnus"
          then "HDMI-1"
          else "eDP-1";

        scripts = {
          message-sound = {
            exec = "${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message-new-instant.oga";
            app-name = "^j?iamb$";
          };
        };
        # Keep config fairly close to swaync defaults, but
        # we can tweak a few UX bits here if desired later.

        # Roughly mimic your old dunst padding / rounding.
        style = ''
          .notification-row {
            margin: 4px 0;
          }

          .notification {
            padding: 16px;
            border-radius: 20px;
          }

          .notification .title {
            font-weight: bold;
          }
        '';
      };
    };
  };
}
