{
  unify.home = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
    ];
  };
}
