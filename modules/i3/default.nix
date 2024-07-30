{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [./picom.nix];

  options.i3.enable = lib.mkEnableOption "enables i3wm";

  config = lib.mkIf config.i3.enable {
    picom.enable = true;

    services = {
      libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
      };

      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "dvorak";
          options = "caps:escape";
        };
        autoRepeatDelay = 225;
        autoRepeatInterval = 20;

        windowManager.i3 = {
          enable = true;
          configFile = ./i3.config;
        };
      };
    };
    home-manager.users.joshammer.services.polybar = {
      enable = true;
      package = pkgs.polybar.override {pulseSupport = true;};
      script = "polybar main & disown";
      config = ./polybar.ini;
    };
  };
}
