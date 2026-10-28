{inputs, ...}: let
  domain = "joshammer.com";
  port = 3000;
in {
  flake.modules.nixos.grapple = {
    config,
    pkgs,
    ...
  }: let
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

    # joshammer.com/workout's password (the workout from hjem, on a phone).
    # Root-only; systemd hands it to the service as the credential
    # `workout-password`, which is where malleusite looks for it.
    sops.secrets.workout_password = {
      sopsFile = ../secrets/workout.yaml;
      key = "password";
    };

    # --- Systemd Service ---
    systemd.services.grapple-game = {
      description = "Grapple Game (malleusite)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${grapplePkg}/bin/malleusite";
        WorkingDirectory = "/var/lib/grapple";
        Restart = "always";
        User = "grapple";
        Group = "grapple";
        StateDirectory = "grapple";
        LoadCredential = ["workout-password:${config.sops.secrets.workout_password.path}"];
        Environment = [
          "PORT=${toString port}"
          "HOME=/var/lib/grapple"
          # joshammer.com/mc reads the Minecraft server's per-player stats
          # straight off disk (mc.nix). Paper writes them world-readable, so
          # this is all it takes. Deliberately NOT the minecraft group:
          # server.properties is 0640 because it holds the RCON password, and
          # an internet-facing process has no business being able to read it.
          "MC_DIR=/var/lib/minecraft"
        ];

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
      };
    };

    # Redirect joshammer.xyz -> joshammer.com (301 permanent)
    services.nginx.virtualHosts."joshammer.xyz" = {
      forceSSL = true;
      enableACME = true;
      globalRedirect = "joshammer.com";
    };
  };
}
