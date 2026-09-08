{
  unify.modules.gui.nixos = {pkgs, ...}: {
    hardware.bluetooth.enable = true;

    # Headsets reconnect on their own when they power on. bluez asks a
    # registered agent to authorize the incoming A2DP/AVRCP/HFP services, and
    # with no agent it rejects them -- the headset associates, gets denied, and
    # drops a couple of seconds later:
    #
    #   bluetoothd: Authentication attempt without agent
    #   bluetoothd: profiles/audio/a2dp.c:auth_cb() Access denied: org.bluez.Error.Rejected
    #
    # An outgoing `bluetoothctl connect` skips authorization, which is why the
    # manual reconnect always worked. Trusted devices skip it too, so keep
    # every paired device trusted.
    #
    # Trust is stored in /var/lib/bluetooth, so a boot-time pass would leave a
    # freshly paired device broken until the next reboot. Hence the D-Bus
    # watch: org.bluez emits InterfacesAdded when a device object appears, and
    # `devices Paired` filters out the discovery noise.
    systemd.services.bluetooth-auto-trust = {
      description = "Keep paired Bluetooth devices trusted";
      after = ["bluetooth.service"];
      requires = ["bluetooth.service"];
      wantedBy = ["bluetooth.target"];
      path = with pkgs; [bluez dbus];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;
      };
      script = ''
        trust_paired() {
          bluetoothctl devices Paired 2>/dev/null | while read -r _ mac _; do
            bluetoothctl trust "$mac" >/dev/null 2>&1 || true
          done
        }

        trust_paired

        dbus-monitor --system \
          "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded'" \
          | while read -r line; do
              case "$line" in
                *"/org/bluez/hci"*"/dev_"*) trust_paired ;;
              esac
            done
      '';
    };
  };
}
