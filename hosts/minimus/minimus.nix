{
  hosts.minimus = {
    tags = [
      "balefire"
      "cerbo-client"
      "efi"
      "grapple"
      "matrix"
      "mc"
      "mechphyll"
      "pipedream"
      "reverse-ssh-hub"
      "ultimate-grapple"
    ];

    modules = [
      ./_hardware-configuration.nix
      ./_network.nix
      ./_server.nix
    ];
  };
}
