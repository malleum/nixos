{
  unify.modules.gui.nixos = {
    pkgs,
    config,
    ...
  }: let
    sessions = "${config.services.displayManager.sessionData.desktops}/share";
    tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
  in {
    # A plain login-shell entry so "shell" is selectable alongside jay/hyprland.
    environment.etc."greetd/sessions/shell.desktop".text = ''
      [Desktop Entry]
      Name=Shell
      Comment=Plain login shell
      Exec=${pkgs.bashInteractive}/bin/bash -l
      Type=Application
    '';

    # Without this, late-boot console output (systemd unit status, kernel
    # messages) is still written to the VT tuigreet is drawing on and paints
    # over the form. Quiet the console, and let greetd own the tty: Type=idle
    # holds the start until the rest of the boot job queue is drained, and the
    # TTY* settings hand it a cleared VT.
    boot.consoleLogLevel = 0;
    boot.kernelParams = ["quiet" "udev.log_level=3"];
    boot.initrd.verbose = false;

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        # --remember: last username, --remember-session: last picked session
        # (jay/hyprland/shell). tuigreet pre-selects it as the default.
        command = "${tuigreet} --time --asterisks --cmd 'jay run' --remember --remember-session --sessions ${sessions}/wayland-sessions:${sessions}/xsessions:/etc/greetd/sessions";
        user = "greeter";
      };
    };
  };
}
