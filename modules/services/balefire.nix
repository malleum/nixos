# balefire (github:malleum/balefire) — a survival roguelite. The game is static
# files plus a small relay that hands out room codes and forwards bytes between
# players. The relay serves both, so this is one upstream on one port.
#
# Interim: the checkout lives in ~/balefire and is built by hand with npm; this
# module only exposes and supervises it. See docs/NIXOS.md in that repo.
#
# No new ports — nginx already owns 80/443 (enabled by the matrix module) and
# the Oracle VCN already permits them. 8090 rather than the obvious 8080, which
# lk-jwt-service already has.
{
  unify.modules.balefire.nixos = {
    hostConfig,
    pkgs,
    ...
  }: let
    domain = "balefire.joshammer.com";
    port = 8090;
    upstream = "http://127.0.0.1:${toString port}";
    checkout = "/home/${hostConfig.user.username}/balefire";
  in {
    services.nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;

      # The page and its one JavaScript file.
      locations."/".proxyPass = upstream;

      # The websocket. Split out from "/" rather than folded into it so the
      # Upgrade headers and the long read timeout apply only where they mean
      # something; nginx picks the longest matching prefix. Without
      # proxyWebsockets the page loads perfectly and *joining a room* fails,
      # which is a confusing way to find out.
      locations."/ws" = {
        proxyPass = upstream;
        proxyWebsockets = true;
        extraConfig = "proxy_read_timeout 3600s;";
      };
    };

    # Runs the hand-built checkout. This is the part that disappears once
    # balefire exports its own flake.
    systemd.services.balefire = {
      description = "balefire relay";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      environment.PORT = toString port;
      path = [pkgs.nodejs_22];

      serviceConfig = {
        ExecStart = "${pkgs.nodejs_22}/bin/node packages/relay/dist/index.js";
        WorkingDirectory = checkout;
        User = hostConfig.user.username;
        Restart = "on-failure";
        RestartSec = 5;

        # Lighter than grapple's hardening on purpose: this runs out of a home
        # directory the user edits, so ProtectSystem/PrivateTmp would fight the
        # workflow. The dedicated user and full hardening arrive with the flake.
        NoNewPrivileges = true;
      };
    };
  };
}
