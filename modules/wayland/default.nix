{
  imports = [./waybar.nix ./sway.nix ./hypr.nix];

  config = {
    wm = "sway";
    services.displayManager.ly = {
      enable = true;
    };

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
