{
  hosts.malleum = {
    tags = [
      "ai"
      "amd"
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
