{
  unify.modules.gam.nixos = {
    services.udev.extraRules = ''
      # Grant access to Endgame Gear mice (e.g. OP1 / OP1 8k) for WebHID and UnofficialEGGMouseConfig
      KERNEL=="hidraw*", ATTRS{idVendor}=="3367", MODE="0666", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="3367", MODE="0666", TAG+="uaccess"
    '';
  };
}

