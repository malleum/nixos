{
  unify.modules.gui.nixos = {pkgs, ...}: {
    programs = {
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [obs-pipewire-audio-capture wlrobs];
      };
    };
  };
}
