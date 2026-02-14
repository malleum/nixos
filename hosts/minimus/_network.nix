# Oracle Cloud static networking; open ports in VCN Security List (Ingress Rules) as needed
{lib, ...}: {
  networking = {
    networkmanager.enable = lib.mkForce false;
    defaultGateway = "10.0.0.1";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
    interfaces.enp0s6 = {
      ipv4.addresses = [
        {
          address = "10.0.0.208";
          prefixLength = 24;
        }
      ];
      useDHCP = false;
    };
    firewall = {
      logRefusedConnections = false;
      rejectPackets = true;
    };
  };
}
