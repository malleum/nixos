# MediaTek MT7925 (Filogic 360) WiFi stability fixes
# Addresses 4WAY_HANDSHAKE_TIMEOUT disconnection issues
{
  unify.modules.wif.nixos = {pkgs, ...}: {
    # Disable WiFi power saving in TLP (critical for MT7925 stability)
    services.tlp.settings = {
      # Disable WiFi power management entirely
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";

      # Ensure runtime PM doesn't affect WiFi
      RUNTIME_PM_DRIVER_DENYLIST = "mt7925e";
    };

    # Disable NetworkManager WiFi power saving
    networking.networkmanager.wifi.powersave = false;

    # Ensure proper MAC address handling (helps with some roaming issues)
    networking.networkmanager.wifi.macAddress = "preserve";

    # Kernel parameters to help with MT7925 stability
    boot.kernelParams = [
      # Disable PCIe ASPM for the WiFi device (can cause timing issues)
      "pcie_aspm=off"
    ];

    # Disable WiFi power saving after powertop runs (fixes MT7925 issues)
    systemd.services.wifi-powersave-off = {
      description = "Disable WiFi power saving";
      wantedBy = ["multi-user.target"];
      after = ["NetworkManager.service" "powertop.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'for dev in $(${pkgs.iw}/bin/iw dev | ${pkgs.gnugrep}/bin/grep Interface | ${pkgs.coreutils}/bin/cut -d\" \" -f2); do ${pkgs.iw}/bin/iw dev \"$dev\" set power_save off || true; done'";
        RemainAfterExit = true;
      };
    };
  };
}
