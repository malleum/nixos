# Reverse SSH tunnel: magnus (behind home NAT) dials out to minimus (public
# Oracle box) and holds a remote forward, so magnus is reachable from anywhere
# that can reach minimus.
#
#   client --ssh--> minimus:22 --127.0.0.1:2222--> tunnel --> magnus:22
#
# The forward binds to minimus's loopback only -- no new public port, no VCN
# rule. Clients hop through with ProxyJump (the `magnus` block in
# modules/programs/ssh.nix), so both hops are authenticated end to end.
#
# The tunnel logs in as a dedicated `tunnel` user on minimus whose key can do
# nothing but listen on localhost:2222: no shell, no pty, no local forwards.
# The private half lives in secrets/reverse-ssh.yaml.
let
  port = 2222;

  tunnelPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEg2YROL7Nl2smxm+tijtdzdQHqRSbQCxwMGvQZT3v2 reverse-tunnel@magnus";

  # Same key minimus authorizes in hosts/minimus/_server.nix; every host gets
  # its private half at ~/.ssh/oracle via sops.
  oraclePubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+i3+8ZbQPDjp4Te8k7A11JLxMPMCiciUTtHDLBzLlvNK/F+2+UIviqCePxAkH/TAjjoU55T8ycEPDZr3li5id0T5qnAlAFT5AKtheyg76AHq/7rh+SQISRSdKNiLSblabd8iA62odFvU+7/KfFPj9fdnX5495+f3NkH8a5ZsXYhFxtU7rpEgiYEAWT3/GFb31+MxKTtP8zsCrtybCOJY2uNp6U6PGWcVsgOiS2N8Ew0a3Fb7UCRhdipOV34Nl92EaswBbOt2jjjukkjwFuhlw6gaCRxJM5UsynAu0YDISrW8yI8apI2oT9TCzLtO4IiL9iuGn5AI4wYjrrYdZLbNz ssh-key-2026-02-14";
in {
  # Pinned so neither the tunnel service nor ProxyJump clients ever TOFU the
  # first hop. Verified against minimus's age recipient in .sops.yaml.
  flake.modules.nixos.base = {
    programs.ssh.knownHosts.minimus = {
      hostNames = ["minimus" "oracle" "158.101.121.4"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6Z2xMaLOJDTmpCqAcX27wnJx0fSIBN9UB25RWR9U2i";
    };
  };

  # minimus side: accept the tunnel.
  flake.modules.nixos.reverse-ssh-hub = {pkgs, ...}: {
    users.groups.tunnel = {};
    users.users.tunnel = {
      isSystemUser = true;
      group = "tunnel";
      shell = "${pkgs.shadow}/bin/nologin";
      openssh.authorizedKeys.keys = [
        ''restrict,port-forwarding,permitlisten="localhost:${toString port}" ${tunnelPubKey}''
      ];
    };

    # Belt and braces on top of the key options, plus a short keepalive: if
    # magnus drops off without a FIN (reboot, NAT timeout), the stale session
    # still owns :2222 and the reconnect's forward fails until sshd reaps it.
    services.openssh.extraConfig = ''
      Match User tunnel
        AllowTcpForwarding remote
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        X11Forwarding no
        PermitTTY no
        ClientAliveInterval 15
        ClientAliveCountMax 3
    '';
  };

  # magnus side: hold the tunnel open, and let the oracle key in.
  flake.modules.nixos.reverse-ssh = {
    hostConfig,
    pkgs,
    ...
  }: {
    sops.secrets.reverse_ssh_private = {
      sopsFile = ../secrets/reverse-ssh.yaml;
      key = "private_key";
    };

    users.users.${hostConfig.user.username}.openssh.authorizedKeys.keys = [oraclePubKey];

    systemd.services.reverse-ssh = {
      description = "Reverse SSH tunnel to minimus (localhost:${toString port} -> magnus:22)";
      wants = ["network-online.target"];
      after = ["network-online.target" "sshd.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        DynamicUser = true;
        LoadCredential = "key:/run/secrets/reverse_ssh_private";
        # -F /dev/null: ignore any ssh_config; everything is stated here.
        # ExitOnForwardFailure makes a stale listener on minimus a hard
        # failure so systemd retries instead of idling with no forward.
        ExecStart = builtins.concatStringsSep " " [
          "${pkgs.openssh}/bin/ssh -N -F /dev/null"
          "-i %d/key"
          "-o IdentitiesOnly=yes"
          "-o StrictHostKeyChecking=yes"
          "-o GlobalKnownHostsFile=/etc/ssh/ssh_known_hosts"
          "-o UserKnownHostsFile=/dev/null"
          "-o ExitOnForwardFailure=yes"
          "-o ServerAliveInterval=15"
          "-o ServerAliveCountMax=3"
          "-R localhost:${toString port}:localhost:22"
          "tunnel@158.101.121.4"
        ];
        Restart = "always";
        RestartSec = 10;
      };
      # Never give up retrying (default burst limit would stop after 5 fast fails).
      startLimitIntervalSec = 0;
    };
  };
}
