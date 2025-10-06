{pkgs, ...}: {
  imports = [./waybar.nix ./sway.nix ./hypr.nix];

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
    };
  };
}
