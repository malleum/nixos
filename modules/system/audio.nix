{
  unify.modules.gui.nixos = {config, ...}: {
    security.rtkit.enable = true;

    services = {
      pulseaudio.enable = false;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
    };
    users.users.${config.user.username}.extraGroups = ["audio"];
  };
}
