# Qualcomm WCN7850 / ath12k WiFi roaming fixes.
#
# Symptom: on a multi-AP network the router sends 802.11v BSS Transition
# Management frames ("WNM: Disassociation Imminent"), wpa_supplicant obeys
# immediately, and the client ping-pongs between mesh nodes -- observed
# roaming 5260 MHz <-> 5540 MHz twice within 40 seconds. Every roam is a full
# reauth + reassoc + 4-way handshake, i.e. a few hundred ms of dead air, which
# shows up as a lag spike in games. The ath12k `failed to pull fw stats: -71`
# lines in dmesg are a symptom of the reassoc, not a separate fault.
#
# Fix: use iwd, and then stop it roaming at all.
#
# iwd alone was not enough. It correctly refuses to trust the frames the far
# node sends, which turns each roam into a ~16 s outage rather than a ~0.5 s
# one:
#
#   roam-scan -> roam-info bss d0, signal -77   (current BSS was -69)
#   roaming -> connected                         ("succeeds")
#   unprotected disconnect  reason=15            (4-way handshake timeout)
#   unprotected disconnect  reason=7             (class-3 frame, not assoc)
#   SA Query timed out, connection is invalid. Disconnecting...
#   ...7 s later, reconnect to the original BSS
#
# One mesh node (c0:2e:1d:fa:d0:d0, and once ...cc) accepts the reassociation
# and then behaves as if the station never associated, sending *unprotected*
# deauth frames. 802.11w makes iwd ignore those and run an SA Query; the node
# never answers, so iwd tears the link down. The node is at fault -- the real
# fix is on the router (reset that node, or turn off band / AP steering) --
# but nothing on this host can make a roam onto it succeed.
#
# So: never roam. RoamThreshold5G is dropped far below the ~-66 dBm this host
# actually sees, and DisableRoamingScan stops the roam scan outright. This is
# equivalent to pinning a BSSID, without the failure mode of one: pinning via
# NetworkManager's 802-11-wireless.bssid does nothing under the iwd backend
# (NM only hands iwd the SSID), and pinning in general means an AP that goes
# away leaves the host with nothing to connect to. Here, if the current BSS
# disappears, iwd disconnects and autoconnect picks the best BSS available.
{
  unify.modules.ath.nixos = {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = false;
          # Defaults are -70 / -76 (and -80 / -82 critical). Set below any
          # level at which this link is still usable, so a roam is never
          # considered while the connection is fine.
          RoamThreshold = -85;
          RoamThreshold5G = -85;
          CriticalRoamThreshold = -88;
          CriticalRoamThreshold5G = -88;
          RoamRetryInterval = 60;
        };
        Scan = {
          DisablePeriodicScan = true;
          # The actual "do not roam" switch: no roam scan, so no roam.
          DisableRoamingScan = true;
        };
      };
    };

    networking.networkmanager.wifi = {
      backend = "iwd";
      macAddress = "preserve";
      scanRandMacAddress = false;
    };
  };
}
