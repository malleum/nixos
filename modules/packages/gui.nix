{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      code-cursor-fhs
      losslesscut-bin
      vlc

      gpclient
      networkmanagerapplet

      hunspellDicts.en-us
      stable.libreoffice
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
