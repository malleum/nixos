{
  hosts.minimus = {
    tags = [
      "balefire"
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
