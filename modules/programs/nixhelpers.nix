{
  flake.modules.nixos.base = {pkgs, ...}: {
    programs = {
      nix-ld = {
        enable = true;
        libraries = with pkgs; [glib];
      };
    };
  };
}
