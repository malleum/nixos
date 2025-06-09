{pkgs, ...}: {
  config = {
    services = {
      xserver = {
        enable = true;
        windowManager.i3 = {
          enable = true;
          package = pkgs.i3-gaps;
          configFile = "/home/joshammer/.config/nixos/modules/twm/i3.conf";
          extraPackages = with pkgs; [
            i3status
            i3lock
            i3blocks
            scrot
            xclip
            picom
          ];
        };

        xkb = {
          layout = "us,us";
          variant = "dvorak,";
          options = "caps:escape";
        };
        # Key repeat settings
        autoRepeatDelay = 225;
        autoRepeatInterval = 50;
      };

      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          tapping = true;
        };
      };
    };
  };
}
