# MediaTek MT7925 (Filogic 360) WiFi quirks. iwd itself is the backend on
# every host (modules/system/network.nix); this is only what the card needs.
#
# Symptom that led here: the AP band-steers to 6 GHz, the mt7925e firmware
# fails 6 GHz auth (AssocResp status=30, deauth reason 6) and the driver
# wedges until NM stops answering D-Bus. ANQP and PMKSA caching are off, and
# ASPM is disabled on the PCIe link.
{
  flake.modules.nixos.wif = {
    networking.wireless.iwd.settings = {
      General = {
        DisableANQP = true;
        DisablePMKSA = true;
      };
      DriverQuirks.DefaultInterface = "*";
    };

    boot.extraModprobeConfig = ''
      options mt7925e disable_aspm=1
    '';
  };
}
