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
    [Minecraft*]

    capslock = 0
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
        RestartSec = 1;
        User = "root";
        NoNewPrivileges = false;
        ProtectSystem = false;
        ProtectHome = false;
      };
    };
  };

  home-manager.users.joshammer.systemd.user.services = {
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
        RestartTriggers = [
          config.home-manager.users.joshammer.xdg.configFile."keyd/app.conf".source
        ];
      };
    };
  };
  users.groups.keyd = {};
}
