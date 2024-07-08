{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];

  options.hypr.enable = lib.mkEnableOption "enables wayland WMs";

  config = lib.mkIf config.hypr.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    environment = {
      sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";

        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    home-manager.users.joshammer = {
      imports = [./waybar.nix];
      home.file = {
        ".config/hypr/hyprland.conf".text =
          ''
            source = ~/.config/nixos/modules/hypr/hyprland.conf

            general {
              col.active_border = rgba(${config.stylix.base16Scheme.base04}ff) rgba(${config.stylix.base16Scheme.base0C}ff) 30deg
              col.inactive_border = rgba(${config.stylix.base16Scheme.base01}aa)
            }

          ''
          + (
            if (config.networking.hostName != "magnus")
            then "monitor=HDMI-A-1,1920x1080,1920x0,1"
            else ""
          );
      };
    };
  };
}
