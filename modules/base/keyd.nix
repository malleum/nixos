{
  config,
  pkgs,
  ...
}: {
  environment.etc."keyd/default.conf".text = ''
    [ids]
    *

    [main]
    capslock = esc
  '';

  home-manager.users.joshammer.xdg.configFile."keyd/app.conf".text = ''
    [*minecraft*]
    capslock = backspace
  '';

  systemd = {
    services.keyd-manual = {
      description = "keyd remapping daemon";
      wantedBy = ["multi-user.target"];
      after = ["local-fs.target"];

      restartTriggers = [
        config.environment.etc."keyd/default.conf".source
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.keyd}/bin/keyd";
        Restart = "always";
        RestartSec = 37;
        User = "root";
        NoNewPrivileges = false;
        ProtectSystem = false;
        ProtectHome = false;
      };
    };
  };

  home-manager.users.joshammer = {
    systemd.user.services = {
      keyd-application-mapper = {
        Unit = {
          Description = "keyd application mapper";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };

        Service = {
          ExecStart = ''${pkgs.fish}/bin/fish -c 'DISPLAY="" ${pkgs.keyd}/bin/keyd-application-mapper' '';
          Restart = "always";
          RestartSec = 1;
          RestartTriggers = [config.home-manager.users.joshammer.xdg.configFile."keyd/app.conf".source];
        };
      };
    };

    # Conditionally create ~/.XCompose symlink
    home.file.".XCompose" = let
      keydCompose = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/rvaiya/keyd/master/data/keyd.compose";
        sha256 = "sha256-Oyob27hiS4KxRa8fimllANs9uHG0hTfrWk70c5G9Myc=";
      };
    in {
      source = keydCompose;
      # Only create the symlink if ~/.XCompose doesn't exist
      onChange = ''
        if [ -e "$HOME/.XCompose" ]; then
          echo "Skipping symlink creation: ~/.XCompose already exists"
        else
          ln -sf ${keydCompose} $HOME/.XCompose
        fi
      '';
    };
  };
  users.groups.keyd = {};
}
