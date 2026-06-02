# Binary cache server for malleum.us. Runs harmonia behind nginx (ACME TLS),
# accepts pushes via SSH (`nix copy --to ssh-ng://nix-uploader@malleum.us`)
# from hosts running the `cch` module, and exposes /nix/store over HTTP
# signed with the malleum.us-1 key.
#
# Setup notes are in modules/services/cch.nix. The two pubkeys live here
# (SSH authorized_keys) and there (binary cache trusted-public-keys).
{
  unify.modules.cache-server.nixos = {
    pkgs,
    config,
    ...
  }: let
    cacheDomain = "malleum.us";

    # PUBLIC half of the ssh key whose private half is at
    # sops:cch_ssh_private on every `cch` host. Replace before first deploy.
    cchSshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdN3i1zHLA76qal/llfEkfT7q0cPDbTDs+8//KIXe3O cch-uploader";
  in {
    # SSH-only system user. The shell exists so nix-daemon's ssh-ng protocol
    # can spawn `nix-daemon --stdio` on connect; the user is otherwise inert.
    users.users.nix-uploader = {
      isSystemUser = true;
      group = "nix-uploader";
      home = "/var/lib/nix-uploader";
      createHome = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [cchSshPubKey];
    };
    users.groups.nix-uploader = {};

    # Required: trusted-users can `nix copy --to ssh-ng://...` without
    # signed paths; harmonia signs at serve time, not at receive time.
    nix.settings.trusted-users = ["nix-uploader"];

    # GC root directory. One symlink per pushed pkg-name; replacing the
    # symlink drops the prior path's only root, so nix-collect-garbage
    # purges old versions automatically.
    systemd.tmpfiles.rules = [
      "d /var/lib/laptop-cache 0755 nix-uploader nix-uploader -"
    ];

    sops.secrets.cch-signing-key = {
      key = "cch_signing_key";
      owner = "harmonia";
      group = "harmonia";
      mode = "0440";
    };

    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [config.sops.secrets.cch-signing-key.path];
      settings = {
        bind = "127.0.0.1:5000";
        priority = 30;
      };
    };

    services.nginx.virtualHosts.${cacheDomain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5000";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];

    # Old paths are dropped on each push (client replaces the gcroot symlink
    # and triggers nix-collect-garbage). nh's built-in nix.gc handler picks
    # up anything missed on its normal cadence.
  };
}
