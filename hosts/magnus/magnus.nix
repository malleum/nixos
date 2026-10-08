{
  hosts.magnus = {
    tags = [
      "ai"
      "amd"
      "ath"
      "bt-audio"
      "cht"
      "dbt"
      "dev"
      "doc"
      "efi"
      "gam"
      "gui"
      "hyp"
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
