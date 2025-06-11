{
  pkgs,
  lib,
  config,
  ...
}: {
  options.i3.enable = lib.mkEnableOption "Enables i3";
  config = lib.mkIf config.i3.enable {
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
          layout = "us,mcsr,us";
          variant = "dvorak,,";
          options = "caps:escape,grp:sclk_toggle";

          extraLayouts.mcsr = {
            description = "My MCSR epic layout";
            languages = ["nob"];
            symbolsFile = pkgs.writeText "mcsr" ''
              default partial alphanumeric_keys
              xkb_symbols "basic" {
                include "us(dvorak)"
                name[Group1]= "mcsr";

                key <AE01> { [ h, H ] };
                key <AE02> { [ t, T ] };
                key <AE04> { [ aring, Aring ] };

                key <AD01> { [ u, U ] };
                key <AD02> { [ b, B ] };
                key <AD03> { [ oslash, Oslash ] };
                key <AD04> { [ y, Y ] };
                key <AD05> { [ p, P ] };

                key <AC01> { [ l, L ] };
                key <AC02> { [ r, R ] };
                key <AC03> { [ n, N ] };

                key <AB02> { [ a, A ] };
                key <AB03> { [ s, S ] };
                key <AB04> { [ k, K ] };

                key <CAPS> { [ BackSpace, BackSpace ] };
              };
            '';
          };
        };
        autoRepeatDelay = 225;
        autoRepeatInterval = 20;
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
