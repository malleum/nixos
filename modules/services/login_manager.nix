{
  unify.modules.gui.nixos = {
    pkgs,
    config,
    ...
  }: let
    sessions = "${config.services.displayManager.sessionData.desktops}/share";
    tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  in {
    # A plain login-shell entry so "shell" is selectable alongside jay/hyprland.
    environment.etc."greetd/sessions/shell.desktop".text = ''
      [Desktop Entry]
      Name=Shell
      Comment=Plain login shell
      Exec=${pkgs.bashInteractive}/bin/bash -l
      Type=Application
    '';

    services.greetd = {
      enable = true;
      settings.default_session = {
        # --remember: last username, --remember-session: last picked session
        # (jay/hyprland/shell). tuigreet pre-selects it as the default.
        command = "${tuigreet} --time --asterisks --remember --remember-session --sessions ${sessions}/wayland-sessions:${sessions}/xsessions:/etc/greetd/sessions";
        user = "greeter";
      };
    };
  };
}
