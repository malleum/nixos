{pkgs, ...}: {
  imports = [./waybar.nix ./eww.nix ./sway.nix ./hypr.nix ./i3.nix ./polybar.nix];

  config = {
    wm = "hyprland";
    services.displayManager.ly.enable = true;

    systemd.user.services = {
      # Clipboard manager
      cliphist = {
        description = "Clipboard manager";
        wantedBy = ["graphical-session.target"];
        after = ["graphical-session.target"];
        partOf = ["graphical-session.target"]; # Add this
        serviceConfig = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "always";
          RestartSec = 3; # Add delay
        };
      };

      # OneDrive sync - needs network
      onedrive = {
        description = "OneDrive sync";
        wantedBy = ["default.target"];
        after = ["network-online.target"]; # Wait for network
        wants = ["network-online.target"];
        serviceConfig = {
          ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };

    home-manager.users.joshammer = {pkgs, ...}: {
      systemd.user.services = {
        spotifyplayer = {
          Unit = {
            Description = "Spotify player daemon";
            After = ["network-online.target"];
            Wants = ["network-online.target"];
          };

          Install = {
            WantedBy = ["default.target"];
          };

          Service = {
            ExecStart = "${pkgs.spotify-player}/bin/spotify-player";
            Restart = "always";
            RestartSec = 1;
          };
        };
      };
    };
  };
}
