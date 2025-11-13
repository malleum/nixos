{inputs, ...}: {
  unify.home = {pkgs, ...}: let
    inherit (pkgs.stdenv.hostPlatform) system;
    nixvim' = inputs.nixvim.legacyPackages.${system};
    nixvimModule = {
      inherit system;
      module = import ../../nixvim;
      extraSpecialArgs = {inherit pkgs system;};
    };
    nixvimPackage = nixvim'.makeNixvimWithModule nixvimModule;
  in {
    home.packages = with pkgs; [
      acpi
      age
      bat
      bc
      btop
      choose
      fastfetch
      fd
      feh
      ffmpeg
      file
      fzf
      htop
      imagemagick
      jq
      killall
      libnotify
      libqalculate
      ltrace
      magic-wormhole
      nitch
      nix-prefetch-github
      nixvimPackage
      nmap
      openssl
      ouch
      rip2
      ripgrep
      sd
      sops
      speedtest-cli
      tldr
      wget
      xan
    ];
  };
}
