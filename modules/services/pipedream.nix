# pipedream (github:malleum/pipedream) — the combined-arms vehicle builder's
# multiplayer relay. Players join from the game's pause menu (Multiplayer →
# Connect); the default server is wss://joshammer.com/pipedream/ws. The relay
# hands out player ids and forwards each player's messages to the others in
# their room; the game clients do the rest. Nothing is written to disk.
#
# No new ports: the relay listens on loopback and nginx (which already owns
# 80/443 for joshammer.com, see grapple.nix) forwards the WebSocket. 8091 sits
# next to balefire's 8090.
{inputs, ...}: {
  flake.modules.nixos.pipedream = {
    imports = [inputs.pipedream.nixosModules.relay];

    services.pipedream-relay = {
      enable = true;
      port = 8091;
    };

    # Without proxyWebsockets the upgrade fails and the game just says it
    # couldn't reach the server. Long read timeout: a quiet room is not a dead one.
    services.nginx.virtualHosts."joshammer.com".locations."/pipedream/ws" = {
      proxyPass = "http://127.0.0.1:8091";
      proxyWebsockets = true;
      extraConfig = "proxy_read_timeout 3600s;";
    };
  };
}
