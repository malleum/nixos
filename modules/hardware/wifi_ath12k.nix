# Qualcomm WCN7850 / ath12k WiFi.
#
# ROOT CAUSE, found 2026-09-19: the antenna was never screwed onto the rear
# RP-SMA jacks. Everything below was diagnosed on a host with a ~29 dB RF
# deficit, so most of it was treating symptoms of that.
#
# With the antenna connected:
#
#   signal       -38 dBm [-40, -43]   (was -67 [-68, -74], one wall from the AP)
#   tx bitrate   1080.6 Mbit/s HE-MCS 10 NSS 2   (was 17.2 Mbit/s, HE-MCS 0)
#   rx bitrate   600.4 Mbit/s  HE-MCS 11
#   gateway rtt  4.46 ms avg, mdev 0.95   (was 15.3 ms avg, mdev 16.5)
#   speedtest    264 down / 199 up Mbit/s (was 12.7 / 1.4)
#
# The failure mode is worth remembering because it does not look like a dead
# antenna: the card still HEARS a nearby AP fine, so the link associates and
# reports a plausible RSSI. It just cannot be heard back. That one-way link
# is what produced the original symptoms --
#
#   - reassociations that "succeed" and then collapse, with the far node
#     sending unprotected deauth and never answering the SA Query. A station
#     the AP can barely hear looks exactly like this from the AP side. The
#     node blamed below (c0:2e:1d:fa:d0:d0) was probably innocent.
#   - tx rate control pinned at the floor, hence ~12 Mbit/s of real
#     throughput regardless of band, and flat across 1/4/8 parallel streams
#     because the shared uplink ACK path was the bottleneck.
#   - driver default tx power sitting at 1 dBm against a 30 dBm regulatory
#     ceiling.
#
# Original symptom, recorded before the antenna was found: on a multi-AP
# network the router sends 802.11v BSS Transition Management frames ("WNM:
# Disassociation Imminent") and the client ping-pongs between mesh nodes --
# roaming 5260 MHz <-> 5540 MHz twice within 40 seconds, every roam a full
# reauth + reassoc + 4-way handshake, showing up as a lag spike in games.
# Under iwd each roam became a ~16 s outage instead:
#
#   roam-scan -> roam-info bss d0, signal -77   (current BSS was -69)
#   roaming -> connected                         ("succeeds")
#   unprotected disconnect  reason=15            (4-way handshake timeout)
#   unprotected disconnect  reason=7             (class-3 frame, not assoc)
#   SA Query timed out, connection is invalid. Disconnecting...
#
# That was answered with never-roam settings: RoamThreshold{,5G} = -85,
# Critical* = -88, and DisableRoamingScan + DisablePeriodicScan. Those are
# now REMOVED. They were expensive -- a host that cannot scan cannot find a
# better AP, so whatever it landed on at boot is where it stayed. On
# 2026-09-19 that meant sitting on a 2.4 GHz 802.11n BSS at 13 Mbit/s for
# 6.5 hours while a forced rescan returned exactly one BSS.
#
# So this host is back to stock roaming behaviour, and the open question is
# whether the flapping returns now that the AP can actually hear us. If it
# does, restore the settings from git history -- but re-measure first rather
# than trusting the analysis above, which was made blind.
#
# iwd is kept for now. It was adopted as part of the same workaround, but
# swapping the backend and the roaming policy in one go would make a
# recurrence impossible to attribute. Revisit once this has been stable.
{
  unify.modules.ath.nixos = {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General.EnableNetworkConfiguration = false;

        Rank = {
          # Not a workaround: this host is a desktop a wall from the AP with a
          # 2x2 80 MHz radio, so 2.4 GHz is never the right answer for it. 0.0
          # disables the band for scanning and connecting -- iwd.config(5).
          BandModifier2_4GHz = 0.0;
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
