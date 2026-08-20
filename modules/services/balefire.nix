# balefire (github:malleum/balefire) — static files plus a small relay that
# hands out room codes and forwards bytes between players. The relay serves
# both, so this is one upstream on one port.
#
# Deliberately write-once. The checkout lives in ~/balefire and is built by hand
# with npm, so testing a change is `npm run build` plus a restart — never a
# rebuild. See docs/NIXOS.md in the balefire repo.
#
# No new ports: nginx (from the matrix module) already owns 80/443, and the
# Oracle VCN already permits them. Port 8090 rather than the obvious 8080,
# which lk-jwt-service already has. ACME terms and email also come from the
# matrix module, exactly as grapple's vhost relies on them.
{
  unify.modules.balefire.nixos = {...}: let
    domain = "balefire.joshammer.com";
    upstream = "http://127.0.0.1:8090";
  in {
    services.nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;

      # The page and its one JavaScript file.
      locations."/".proxyPass = upstream;

      # The websocket. Split out from "/" so the Upgrade headers and the long
      # read timeout apply only where they mean something; nginx takes the
      # longest matching prefix. Without proxyWebsockets the page loads
      # perfectly and *joining a room* fails, which is a confusing way to find
      # out.
      locations."/ws" = {
        proxyPass = upstream;
        proxyWebsockets = true;
        extraConfig = "proxy_read_timeout 3600s;";
      };
    };
  };
}
