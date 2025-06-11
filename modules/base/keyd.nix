{pkgs, ...}: {
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

    user.services = {
      keyd-application-mapper = {
        description = "keyd application mapper";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target"];

        serviceConfig = {
          ExecStart = ''${pkgs.fish}/bin/fish -c 'DISPLAY="" ${pkgs.keyd}/bin/keyd-application-mapper' '';
          Restart = "always";
          RestartSec = 1;
        };
      };
    };
  };

  users.groups.keyd = {};
}
