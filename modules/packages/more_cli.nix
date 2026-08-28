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

    xdg.dataFile."qalculate/definitions/units.xml".text = import ../../lib/qalculate_units.nix;
  };
}
