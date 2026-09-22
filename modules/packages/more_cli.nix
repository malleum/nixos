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
      # lerni and termword are uncached flake inputs; they live in
      # modules/meta/source-builds.nix so a host without `src` never builds them.
    ];

    xdg.dataFile."qalculate/definitions/units.xml".text = import ../../lib/qalculate_units.nix;
  };
}
