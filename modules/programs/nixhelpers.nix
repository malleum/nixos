{inputs, ...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    programs = {
      nix-ld = {
        enable = true;
        libraries = with pkgs; [glib];
      };
    };
    environment.systemPackages = [
      # TODO: this can probably be added back soon once nixpkgs updates
      # inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
    ];
  };
}
