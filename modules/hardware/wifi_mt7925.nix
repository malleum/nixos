# MediaTek MT7925 (Filogic 360) WiFi stability fixes.
#
# Symptom: AP band-steers to 6 GHz, mt7925e firmware fails 6 GHz auth
# ("SME: Authentication request to the driver failed", AssocResp status=30,
# deauth reason 6). Driver wedges; NM stops answering D-Bus so nmtui prints
# "NetworkManager is not running" even though the unit is active.
# wpa_supplicant `bgscan simple` keeps re-roaming because the driver lacks
# CQM signal monitoring. Fix: switch backend to iwd (no wpa_supplicant
# bgscan, smarter roaming logic).
{
  unify.modules.wif.nixos = {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = false;
          DisableANQP = true;
          DisablePMKSA = true;
        };
        DriverQuirks.DefaultInterface = "*";
      };
    };

    networking.networkmanager.wifi = {
      backend = "iwd";
      macAddress = "preserve";
      scanRandMacAddress = false;
    };

    boot.extraModprobeConfig = ''
      options mt7925e disable_aspm=1
    '';
  };
}
