{
  hosts.magnus = {
    tags = [
      "ai"
      "amd"
      "ath"
      "cerbo"
      "cht"
      "dbt"
      "dev"
      "doc"
      "efi"
      "gam"
      "gui"
      "med"
      "off"
      "prt"
      "reverse-ssh"
      "src"
      "vrt"
      "wake"
      "wrk"
    ];

    modules = [
      ./_hardware-configuration.nix
      ./_rgb-off.nix
    ];
  };
}
