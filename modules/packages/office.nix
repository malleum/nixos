{
  unify.modules.off.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      hunspell
      hunspellDicts.en-us
      pandoc
      libreoffice
    ];
  };
}
