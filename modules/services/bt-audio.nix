{
  # Bluetooth audio stutter fixes for the WCN7850 combo card (magnus).
  # Root cause is WiFi/BT sharing one RF front-end; these settings kill the
  # aggravators. Wired ethernet on enp10s0 is the real fix for the contention.

  # Fix 3: never USB-autosuspend the Bluetooth controller mid-stream.
  # 0489:e10a is the WCN7850 module's BT interface. Applies on plug/boot.
  unify.modules.bt-audio.nixos = {
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0489", ATTR{idProduct}=="e10a", TEST=="power/control", ATTR{power/control}="on"
    '';
  };

  # Fix 2: drop AAC, prefer SBC. The Linux AAC encoder is jittery under load;
  # SBC uses less airtime and is far steadier over a contended radio. The Bose
  # QC Ultra doesn't accept PipeWire's SBC-XQ bitpool (falls back to plain SBC),
  # but sbc_xq stays first for any other headset that does support it.
  #
  # Delivered via the user's XDG config dir — the system
  # services.pipewire.wireplumber.extraConfig option builds a package but does
  # not get wired into the wireplumber user unit in this setup, so it never
  # loads. wireplumber reads ~/.config/wireplumber/wireplumber.conf.d reliably.
  unify.modules.bt-audio.home = {
    xdg.configFile."wireplumber/wireplumber.conf.d/51-bluez-sbc-xq.conf".text = ''
      monitor.bluez.properties = {
        bluez5.enable-sbc-xq = true
        bluez5.codecs = [ sbc_xq, sbc ]
      }
    '';
  };
}
