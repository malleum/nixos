{pkgs ? import <nixpkgs> {}, ...}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    la = "la -lah";
    nativeBuildInputs = with pkgs; [
      git
      neovim
      nix
    ];
  };
}
