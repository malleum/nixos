{self, ...}: {
  unify.home = {pkgs, ...}: let
    nvim = self.packages.${pkgs.stdenv.hostPlatform.system}.nvim;
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
      nmap
      nvim
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
