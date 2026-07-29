{inputs, ...}: {
  unify.modules.lap.nixos = {
    # common-pc-laptop turns TLP on by default (gated on
    # power-profiles-daemon being off, which it is below).
    imports = [inputs.nixos-hardware.nixosModules.common-pc-laptop];

    services = {
      # Better scheduling for CPU cycles - thanks System76
      system76-scheduler.settings.cfsProfiles.enable = true;

      # Tuning only; the enable comes from common-pc-laptop.
      tlp = {
        settings = {
          CPU_BOOST_ON_AC = 0;
          CPU_BOOST_ON_BAT = 0;
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "power";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 40;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 20;
        };
      };

      # Disable GNOMEs power management
      power-profiles-daemon.enable = false;

      # Enable thermald (only necessary if on Intel CPUs)
      thermald.enable = false;
    };

    # Enable powertop
    powerManagement.powertop.enable = true;
  };
}
