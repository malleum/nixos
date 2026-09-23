# A second waywall, patched for the SDL3 versions of Minecraft.
#
# 26.3 dropped GLFW for SDL3 (com.mojang.blaze3d references org.lwjgl.sdl and
# nothing in org.lwjgl.glfw). SDL3 calls xdg_toplevel.set_parent while bringing
# its window up, and waywall answers that request with
# wl_client_post_implementation_error, which is fatal: the game dies with
# "Wayland display connection closed by server" the moment it creates a window.
# Every other unimplemented xdg_toplevel request in that file -- set_min_size,
# set_max_size -- is a silent no-op, so making this one match is a strict
# relaxation rather than a behaviour change.
#
# It is a separate package, not an override of programs.waywall.package,
# because the runs that get submitted (ranked, RSG, SSG) are played on 1.16
# under stock waywall, and that setup should stay byte-identical to upstream.
# Only the casual 26.3 instance reaches for this one, through the wrapper script
# at ~/.local/share/PrismLauncher/instances/newest/waywall-wrap.sh.
#
# The binary is exposed as `waywall-sdl` so it can sit in the same profile as
# the real one without colliding on bin/waywall.
{
  unify.modules.gam.home = {pkgs, ...}: let
    patched = pkgs.waywall.overrideAttrs (old: {
      pname = "waywall-sdl";

      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace waywall/server/xdg_shell.c \
            --replace-fail \
              'wl_client_post_implementation_error(client, "xdg_toplevel.set_parent is not supported");' \
              ""
        '';
    });

    waywall-sdl =
      pkgs.runCommand "waywall-sdl" {
        meta = patched.meta or {};
      } ''
        mkdir -p $out/bin
        ln -s ${patched}/bin/waywall $out/bin/waywall-sdl
      '';
  in {
    home.packages = [waywall-sdl];
  };
}
