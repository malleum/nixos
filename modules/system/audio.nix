{
  unify.modules.gui.nixos =
    { hostConfig, ... }:
    {
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
      users.users.${hostConfig.user.username}.extraGroups = [ "audio" ];
    };
}
