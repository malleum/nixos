# Mechphyll join-code relay (joshammer.com, UDP 7778).
#
# The game's "Join code" multiplayer: a host registers with the relay and gets
# a five-letter code; friends type the code and the relay forwards messages
# between them. It never runs game rules and keeps no state on disk, so
# nothing here needs backing up. ENet is UDP, so it is reached by host and
# port (joshammer.com:7778), not through nginx.
#
# Oracle Cloud also filters at the VCN: add an ingress rule for UDP 7778 in
# the Security List, or the firewall line below alone does nothing.
{inputs, ...}: {
  flake.modules.nixos.mechphyll = {
    imports = [inputs.mechphyll.nixosModules.relay];

    services.mechphyll-relay = {
      enable = true;
      port = 7778;
      openFirewall = true;
    };
  };
}
