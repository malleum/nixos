{
  lib,
  config,
  ...
}: {
  options.sddm.enable = lib.mkEnableOption "enables sddm loginmanager";

  config = lib.mkIf config.sddm.enable {
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        theme = "aerial-sddm-theme";
      };
      defaultSession = "hyprland";
    };
  };
}
