{inputs, ...}: let
  domain = "joshammer.com";
  port = 3000;
in {
  unify.modules.grapple.nixos = {
    pkgs,
    config,
    ...
  }: {
    # --- Grapple User & Group ---
    users.groups.grapple = {};
    users.users.grapple = {
      isSystemUser = true;
      group = "grapple";
      description = "Grapple Game Service User";
      # Adding user joshammer to the group allows access if needed
    };

    # Add joshammer to grapple group (user requested)
    users.users.joshammer.extraGroups = ["grapple"];

    # --- Systemd Service ---
    systemd.services.grapple-game = {
      description = "Grapple Game (malleusite)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${inputs.grapple.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/malleusite-grapple";
        WorkingDirectory = "${inputs.grapple.packages.${pkgs.stdenv.hostPlatform.system}.default}/share";
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
