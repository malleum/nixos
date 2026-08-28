{inputs, ...}: {
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
      inputs.lerni.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.termword.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    xdg.dataFile."qalculate/definitions/units.xml".text = import ../../lib/qalculate_units.nix;
  };
}
