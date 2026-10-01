{
  flake.modules.homeManager.off = {pkgs, ...}: {
    home.packages = with pkgs; [
      hunspell
      hunspellDicts.en-us
      pandoc
      libreoffice
    ];
  };
}
