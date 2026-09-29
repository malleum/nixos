{
  hosts.minoris = {
    # The wall panel. `hjem` autologins straight into a kiosk browser at boot;
    # quitting it drops back to tuigreet, so this is still an ordinary laptop
    # when you want one. Add as needed:
    #   amd / wif  hardware quirks      hyp  hyprland as a second session
    #   dev        toolchains           cht  matrix + signal
    #   gam        games                med  players, obs, spotify
    #   off        libreoffice          ai   assistant CLIs
    #   doc        docker               vrt  qemu / quickemu
    #   wrk        work tooling         src  build jay+iamb from source
    tags = [
      "efi"
      "gui"
      "hjem"
      "lap"
    ];

    modules = [
      ./_hardware-configuration.nix
      ./_tpm-quirk.nix
    ];
  };
}
