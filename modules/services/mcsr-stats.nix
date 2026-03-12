{inputs, ...}: let
  domain = "malleum.us";
  port = 8001;
in {
  unify.modules.mcsr-stats.nixos = {pkgs, ...}: let
    mcsrPkg = inputs.mcsr-stats.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    # --- MCSR Stats User & Group ---
    users.groups.mcsr-stats = {};
    users.users.mcsr-stats = {
      isSystemUser = true;
      group = "mcsr-stats";
      description = "MCSR Stats Service User";
    };

    # --- Systemd Service ---
    systemd.services.mcsr-stats = {
      description = "MCSR Stats (Tournament Bracket Viewer)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${mcsrPkg}/bin/mcsr-bracket";
        # WorkingDirectory is needed because the script uses current directory as fallback for data
        WorkingDirectory = "/var/lib/mcsr-stats";
        Restart = "always";
        User = "mcsr-stats";
        Group = "mcsr-stats";
        StateDirectory = "mcsr-stats";
      };

      # Initial setup: create data directory and copy default data if not exists
      preStart = ''
        mkdir -p /var/lib/mcsr-stats/data
        if [ ! -f /var/lib/mcsr-stats/data/bracket.json ]; then
          if [ -f ${inputs.mcsr-stats}/data/bracket.json ]; then
            cp ${inputs.mcsr-stats}/data/bracket.json /var/lib/mcsr-stats/data/bracket.json
            chmod 644 /var/lib/mcsr-stats/data/bracket.json
          fi
        fi
      '';

      environment = {
        PORT = toString port;
        MCSR_DATA_DIR = "/var/lib/mcsr-stats/data";
      };
    };

    # --- Nginx Virtual Host ---
    services.nginx.virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
      };
    };
  };
}
