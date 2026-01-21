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
    networking.networkmanager.wifi.scanRandMacAddress = false;

    # Kernel/module parameters to help with MT7925 stability
    boot.extraModprobeConfig = ''
      options mt7925e disable_aspm=1
    '';

    # Disable WiFi power saving after powertop runs (fixes MT7925 issues)
    systemd.services.wifi-powersave-off = {
      description = "Disable WiFi power saving";
      wantedBy = ["NetworkManager.service"];
      after = ["NetworkManager.service" "powertop.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'for dev in $(${pkgs.iw}/bin/iw dev | ${pkgs.gnugrep}/bin/grep Interface | ${pkgs.coreutils}/bin/cut -d\" \" -f2); do ${pkgs.iw}/bin/iw dev \"$dev\" set power_save off || true; done'";
        RemainAfterExit = true;
      };
    };

    # Pin to a stable 5GHz BSSID to avoid 6GHz roam/auth failures.
    systemd.services.nm-wifi-stability = {
      description = "Pin NetworkManager profile to stable BSSID";
      wantedBy = ["NetworkManager.service"];
      after = ["NetworkManager.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.networkmanager}/bin/nmcli -t -f UUID connection show | ${pkgs.gnugrep}/bin/grep -Fx \"e7109b19-9567-4f16-b1bd-c1a312d5619e\" >/dev/null && ${pkgs.networkmanager}/bin/nmcli connection modify \"e7109b19-9567-4f16-b1bd-c1a312d5619e\" 802-11-wireless.bssid \"a6:05:d6:69:1f:c7\" 802-11-wireless.band \"a\" 802-11-wireless.powersave 2 || true'";
        RemainAfterExit = true;
      };
    };
  };
}
