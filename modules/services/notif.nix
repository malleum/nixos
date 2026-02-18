{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = [pkgs.sound-theme-freedesktop];
    services.swaync = {
      enable = true;

      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        timeout = 4239;

        scripts = [
          {
            event = "notification_closed";
            command = "rm $SWAYNC_NOTIF_SOUND_FILE"; # Clean up temporary sound files, if any were created
          }
          {
            event = "notification_hint_sound";
            command = ''
              if [[ "$SWAYNC_NOTIF_HINT_SOUND" == "message-new-instant" ]]; then
                ${pkgs.pipewire}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message-new-instant.ogg &
              fi
            '';
          }
        ];
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
