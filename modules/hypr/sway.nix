{
  lib,
  config,
  ...
}: {
  options.sway.enable = lib.mkEnableOption "enables sway WMs";

  config = lib.mkIf config.sway.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    home-manager.users.joshammer = {
      wayland.windowManager.sway = {
        enable = true;
        # config = {};
      };
    };
  };
}
