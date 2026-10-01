{
  hosts.minimus = {
    tags = [
      "balefire"
      "efi"
      "grapple"
      "matrix"
      "mc"
      "mechphyll"
    ];

    modules = [
      ./_hardware-configuration.nix
      ./_network.nix
      ./_server.nix
    ];
  };
}
