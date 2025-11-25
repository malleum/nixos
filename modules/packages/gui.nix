{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      cherry-studio
      code-cursor-fhs
      iamb
      losslesscut-bin
      vlc

      gpclient
      networkmanagerapplet

      hunspellDicts.en-us
      libreoffice
      hunspell
      pandoc
      gimp

      pavucontrol
      pulsemixer
      pasystray

      nwg-look
      gtk4
      gtk3
    ];
  };
}
