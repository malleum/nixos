{
  unify.modules.med.nixos = {pkgs, ...}: {
    programs = {
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-pipewire-audio-capture
          wlrobs
        ];
      };
    };
  };

  # The MCSR scene collection (Minecraft capture + the Screenshot/Background
  # freeze-filter duplicates that resize_animation_waywall.py drives -- see
  # that script's header comment in the waywall-nix repo for the OBS-side
  # setup it assumes). OBS resaves this file constantly, so it can't be a
  # normal nix-store symlink -- it has to point at the real file in the
  # checked-out repo, and edits made in the OBS UI land straight in the repo
  # working tree for you to `git diff`/commit when a layout is worth keeping.
  unify.modules.gam.home = {config, ...}: {
    home.file.".config/obs-studio/basic/scenes/Untitled.json".source =
      config.lib.file.mkOutOfStoreSymlink
      "/home/joshammer/documents/gh/waywall-nix/obs/scenes/Untitled.json";
  };
}
