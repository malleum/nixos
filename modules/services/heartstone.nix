# Heartstone dedicated server (joshammer.com, UDP 24690).
#
# The meeting point for the Wheel of Time co-op game (github:malleum/heartstone):
# friends on different networks join here instead of forwarding a port, in up to
# eight named rooms at once, and it keeps their characters between sessions
# under /var/lib/heartstone. The game's docs/SERVER.md has the player's side.
#
# 24690, not the game's old default of 24680: that one is ultimate-grapple's.
# ENet is UDP, so it is reached by host and port, not through nginx.
#
# Oracle Cloud also filters at the VCN: add an ingress rule for UDP 24690 in
# the Security List, or the firewall line below alone does nothing.
#
# The word: players must give it to join or to store a character. It lives in
# secrets/heartstone.yaml as one line, `HEARTSTONE_WORD=...`; read or change it
# with `sops modules/secrets/heartstone.yaml`. The transport is not encrypted
# (this Godot has no DTLS), so the word itself never crosses the wire, only a
# one-time proof of it; characters do travel in the clear.
{inputs, ...}: {
  flake.modules.nixos.heartstone = {config, ...}: {
    imports = [inputs.heartstone.nixosModules.default];

    sops.secrets.heartstone_env = {
      sopsFile = ../secrets/heartstone.yaml;
      key = "env";
    };

    services.heartstone = {
      enable = true;
      port = 24690;
      openFirewall = true;
      environmentFile = config.sops.secrets.heartstone_env.path;
    };
  };
}
