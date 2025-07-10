{inputs, ...}: {
  imports = [
    ./lsp.nix
    ./options.nix
    ./plugins.nix
    ./zoom.nix
    inputs.nixvim.nixosModules.nixvim
  ];
  programs.nixvim.enable = true;
}
