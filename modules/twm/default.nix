{pkgs, ...}: {
  imports = [./waybar.nix ./sway.nix ./hypr.nix ./i3.nix];

  config = {
    wm = "hyprland";
    services.displayManager.ly.enable = true;

    systemd.user.services = {
      # Clipboard manager
      cliphist = {
        description = "Clipboard manager";
        wantedBy = ["graphical-session.target"];
        after = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "always";
        };
      };

      # OneDrive sync
      onedrive = {
        description = "OneDrive sync";
        wantedBy = ["default.target"];
        serviceConfig = {
          ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor";
          Restart = "always";
        };
      };

      # Spotify player daemon
      spotify-player = {
        description = "Spotify player daemon";
        wantedBy = ["default.target"];
        serviceConfig = {
          ExecStart = "${pkgs.spotify-player}/bin/spotify_player -d";
          Restart = "always";
        };
      };
    };
  };
}
