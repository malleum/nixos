{inputs, ...}: {
  unify.modules.gam.home = {pkgs, ...}: let
    ninjabrainbot = inputs.waywall.packages.${pkgs.stdenv.hostPlatform.system}.ninjabrainbot;
  in {
    home = {
      packages = with pkgs; [
        ninjabrainbot
        waywall

        prismlauncher
        wl-crosshair

        haguichi
        lumafly

        bottles
        lutris
        protonup-ng
        wine
        winetricks

        vulkan-loader
        vulkan-tools
        vulkan-validation-layers

        libva
        libva-utils
      ];
    };
  };
}
