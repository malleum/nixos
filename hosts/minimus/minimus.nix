{
  hosts.minimus = {
    tags = [
      "balefire"
      "efi"
      "grapple"
      "matrix"
      "mc"
      "mechphyll"
      "ultimate-grapple"
    ];

    modules = [
      ./_hardware-configuration.nix
      ./_network.nix
      ./_server.nix
    ];
  };
}
