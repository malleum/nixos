{inputs, ...}: let
  domain = "joshammer.com";
  port = 3000;
in {
  unify.modules.grapple.nixos = {pkgs, ...}: let
    grapplePkg = inputs.grapple.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    # --- Grapple User & Group ---
    users.groups.grapple = {};
    users.users.grapple = {
      isSystemUser = true;
      group = "grapple";
      description = "Grapple Game Service User";
    };

    users.users.joshammer.extraGroups = ["grapple"];

    # --- Systemd Service ---
    systemd.services.grapple-game = {
      description = "Grapple Game (malleusite)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${grapplePkg}/bin/grapple-game";
        WorkingDirectory = "${grapplePkg}/share";
        Restart = "always";
        User = "grapple";
        Group = "grapple";
        Environment = ["PORT=${toString port}"];

        # Hardening
        ProtectSystem = "full";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # --- Nginx Virtual Host ---
    services.nginx.virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        '';
      };
    };
  };
}
