# Ultimate Grapple dedicated race server (joshammer.com, UDP 24680).
#
# The game's PLAY ONLINE button joins this server, so friends can race
# without port forwarding or being on the same LAN. The server holds the
# lobby and referees "first to X" sets: the first player in picks the
# settings and starts, or everyone readies up. Courses are generated per
# round and nothing is written to disk that needs backing up. ENet is UDP,
# so it is reached by host and port (joshammer.com:24680), not through nginx.
#
# Oracle Cloud also filters at the VCN: add an ingress rule for UDP 24680 in
# the Security List, or the firewall line below alone does nothing.
#
# Not the `grapple` tag: that one is the malleusite website.
{inputs, ...}: {
  flake.modules.nixos.ultimate-grapple = {
    imports = [inputs.ultimate-grapple.nixosModules.server];

    services.ultimate-grapple-server = {
      enable = true;
      port = 24680;
      openFirewall = true;
    };
  };
}
