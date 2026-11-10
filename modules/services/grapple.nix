{inputs, ...}: let
  domain = "joshammer.com";
  port = 3000;
in {
  flake.modules.nixos.grapple = {
    config,
    hostConfig,
    pkgs,
    ...
  }: let
    grapplePkg = inputs.grapple.packages.${pkgs.stdenv.hostPlatform.system}.default;
    inherit (hostConfig.user) username;

    # joshammer.com/lerni is the Esperanto drill on a phone, with the terminal
    # tool's own progress. The tool syncs by reading and writing
    # ~/.cache/lerni/progress.json on this box over ssh; the website serves
    # that same file. It lives in the site's state, group-writable, and the
    # path the tool knows is a symlink to it (lerni-progress-link below), so
    # neither side needs to know about the other.
    lerniDir = "/var/lib/grapple/lerni";
    lerniProgress = "${lerniDir}/progress.json";
    lerniLink = "${config.users.users.${username}.home}/.cache/lerni/progress.json";
  in {
    # --- Grapple User & Group ---
    users.groups.grapple = {};
    users.users.grapple = {
      isSystemUser = true;
      group = "grapple";
      description = "Grapple Game Service User";
    };

    users.users.joshammer.extraGroups = ["grapple"];

    # setgid, so whichever of the two writes the file it stays the group's.
    systemd.tmpfiles.rules = ["d ${lerniDir} 2775 grapple grapple -"];

    # Moves the progress the tool already synced here into the site's state,
    # once, and leaves a symlink where it was. Runs as the user: the directory
    # is group-writable and ${username} is in the group.
    systemd.services.lerni-progress-link = {
      description = "Share lerni's progress file with the website";
      after = ["systemd-tmpfiles-setup.service"];
      before = ["grapple-game.service"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.coreutils];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = username;
        UMask = "0002";
      };
      script = ''
        link=${lerniLink}
        mkdir -p "$(dirname "$link")"
        if [ -f "$link" ] && [ ! -L "$link" ]; then
          # The site's copy wins only if there already is one; either way the
          # old file is kept beside the link rather than deleted.
          [ -e ${lerniProgress} ] || cp "$link" ${lerniProgress}
          mv "$link" "$link.before-website"
        fi
        [ ! -e ${lerniProgress} ] || chmod 664 ${lerniProgress} || true
        ln -sfn ${lerniProgress} "$link"
      '';
    };

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
          "MALLEUSITE_LERNI=${lerniProgress}"
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
