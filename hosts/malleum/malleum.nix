{
  hosts.malleum = {
    tags = [
      "ai"
      "amd"
      "cerbo-client"
      "cht"
      "dev"
      "efi"
      "gui"
      "lap"
      "prt"
      "src"
    ];

    modules = [./_hardware-configuration.nix];
  };
}
