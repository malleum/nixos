{
  pkgs,
  inputs,
  ...
}: {
  vim = {
    theme.enable = true;
    package = inputs.neovim-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
