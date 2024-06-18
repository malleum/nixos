{
  pkgs,
  lib,
  config,
  ...
}: {
  options.greetd.enable = lib.mkEnableOption "enables greetd loginmanager";

  config = lib.mkIf config.greetd.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session.command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --user-menu \
            --cmd Hyprland
        '';
      };
    };
    environment.etc."greetd/environments".text = ''
      Hyprland
    '';
  };
}
