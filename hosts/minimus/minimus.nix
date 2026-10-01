{
  hosts.minimus = {
    tags = [
      "balefire"
      "efi"
      "grapple"
      "matrix"
      "mc"
    ];

    modules = [
      ./_hardware-configuration.nix
      ./_network.nix
      ./_server.nix
    ];
  };
}
