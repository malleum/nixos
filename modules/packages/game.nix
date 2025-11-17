{ inputs, ... }:
{
  unify.modules.gam.home =
    { pkgs, ... }:
    let
      glfwww = inputs.waywall.packages.${pkgs.stdenv.hostPlatform.system}.glfw;
      ninjabrainbot = inputs.waywall.packages.${pkgs.stdenv.hostPlatform.system}.ninjabrainbot;
      waywall-git = inputs.waywall.packages.${pkgs.stdenv.hostPlatform.system}.waywall;
    in
    {
      home = {
        packages = with pkgs; [
          glfwww
          ninjabrainbot
          waywall-git

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
        file.".local/lib64/libglfw.so".source = "${glfwww}/lib/libglfw.so";
      };
    };
}
