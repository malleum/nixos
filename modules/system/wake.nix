# Scheduled wake: a timer with WakeSystem arms the RTC alarm, so a suspended
# machine resumes at `onCalendar`. The service itself does nothing -- waking
# up is the whole point. RTC alarms only fire from suspend/hibernate, not from
# a full poweroff.
let
  onCalendar = "*-*-* 08:00:00";
in {
  flake.modules.nixos.wake = {pkgs, ...}: {
    systemd.timers.scheduled-wake = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = onCalendar;
        WakeSystem = true;
        Persistent = true;
      };
    };

    systemd.services.scheduled-wake = {
      description = "No-op target of the scheduled-wake timer";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };
  };
}
