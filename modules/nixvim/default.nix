{inputs, ...}: {
  unify.nixos = {
    imports = [
      ./_lsp.nix
      ./_options.nix
      ./_plugins.nix
      ./_zoom.nix
      inputs.nixvim.nixosModules.nixvim
    ];
    programs.nixvim.enable = true;
  };
}
