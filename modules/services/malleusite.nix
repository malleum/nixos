{inputs, ...}: let
  domain = "joshammer.com";
  port = 3000;
in {
  flake.modules.nixos.malleusite = {
    config,
    hostConfig,
    pkgs,
    ...
  }: let
    malleusitePkg = inputs.malleusite.packages.${pkgs.stdenv.hostPlatform.system}.default;
    inherit (hostConfig.user) username;

    # joshammer.com/lerni is the Esperanto drill on a phone, with the terminal
    # tool's own progress. The tool syncs by reading and writing
    # ~/.cache/lerni/progress.json on this box over ssh; the website serves
    # that same file. It lives in the site's state, group-writable, and the
    # path the tool knows is a symlink to it (lerni-progress-link below), so
    # neither side needs to know about the other.
    # The site's state stays at /var/lib/grapple, the name from before the
    # rename: moving it would strand the lerni progress and anything else the
    # site has written. systemd re-owns it to the malleusite user on start.
    stateDirName = "grapple";
    stateDir = "/var/lib/${stateDirName}";
    lerniDir = "${stateDir}/lerni";
    lerniProgress = "${lerniDir}/progress.json";
    lerniLink = "${config.users.users.${username}.home}/.cache/lerni/progress.json";
  in {
    # --- malleusite User & Group ---
    users.groups.malleusite = {};
    users.users.malleusite = {
      isSystemUser = true;
      group = "malleusite";
      description = "malleusite website service user";
    };

    users.users.joshammer.extraGroups = ["malleusite"];

    # setgid, so whichever of the two writes the file it stays the group's.
    systemd.tmpfiles.rules = ["d ${lerniDir} 2775 malleusite malleusite -"];

    # Moves the progress the tool already synced here into the site's state,
    # once, and leaves a symlink where it was. Runs as the user: the directory
    # is group-writable and ${username} is in the group.
    systemd.services.lerni-progress-link = {
      description = "Share lerni's progress file with the website";
      after = ["systemd-tmpfiles-setup.service"];
      before = ["malleusite.service"];
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
    systemd.services.malleusite = {
      description = "malleusite website (joshammer.com)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${malleusitePkg}/bin/malleusite";
        WorkingDirectory = stateDir;
        Restart = "always";
        User = "malleusite";
        Group = "malleusite";
        StateDirectory = stateDirName;
        LoadCredential = ["workout-password:${config.sops.secrets.workout_password.path}"];
        Environment = [
          "PORT=${toString port}"
          "HOME=${stateDir}"
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
