# Games and game runtimes. waywall, Ninjabrain-Bot, the CPS overlay and the
# MCSR JDK are not here -- they come with their configuration from
# modules/programs/waywall.nix.
{...}: {
  flake.modules.homeManager.gam = {pkgs, ...}: {
    home = {
      packages = with pkgs; [
        prismlauncher
        wl-crosshair

        haguichi
        lumafly

        bottles
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
