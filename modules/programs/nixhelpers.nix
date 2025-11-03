{inputs, ...}: {
  unify.nixos = {
    pkgs,
    ...
  }: {
    programs = {
      nix-ld = {
        enable = true;
        libraries = with pkgs; [glib];
      };
    };
    environment.systemPackages = [inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien];
  };
}
