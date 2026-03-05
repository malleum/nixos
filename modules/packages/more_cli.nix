{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      acpi
      age
      feh
      ffmpeg
      imagemagick
      libnotify
      libqalculate
      magic-wormhole
      nix-prefetch-github
      openssl
      sops
      speedtest-cli
    ];
  };
}
