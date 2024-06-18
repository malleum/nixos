{
  lib,
  config,
  ...
}: {
  options.lightdm.enable = lib.mkEnableOption "enables lightdm loginmanager";

  config = lib.mkIf config.lightdm.enable {
    services.xserver.displayManager = {
      lightdm = {
        enable = true;
        background = /home/joshammer/OneDrive/Documents/Stuff/pics/car/Tesla/t.jpg;
        greeters.mini = {
          enable = true;
          user = "joshammer";
          extraConfig = ''
            [greeter]
            show-password-label = false
            invalid-password-text = Es malus
            show-input-cursor = false
            password-alignment = right

            [greeter-hotkeys]
            mod-key = meta
            shutdown-key = s
            restart-key = r
            hibernate-key = h
            suspend-key = u

            [greeter-theme]
            font = JetBrainsMono
            font-size = 1em
            text-color = "#080800"
            error-color = "#FF0000"
            background-color = "#000000"
            background-style = stretch
            window-color = "#000033"
            border-color = "#003377"
            border-width = 0px
            layout-space = 2
            password-color = "#003377"
            password-background-color = "#000000"
            password-border-color = "#003377"
            password-border-width = 0px
          '';
        };
      };
      defaultSession = "hyprland";
    };
  };
}
