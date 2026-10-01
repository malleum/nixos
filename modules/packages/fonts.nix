{
  flake.modules.nixos.base = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
    ];
  };
}
