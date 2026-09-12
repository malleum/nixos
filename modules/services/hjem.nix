# hjem (github:malleum/hjem) -- the wall panel. A duodecimal ring clock, the
# weather, and a verse of the day in Esperanto that translates itself one
# phrase per dwell through the afternoon, on an old 12" Dell that does nothing
# else.
#
# The app's own flake carries the server and its NixOS module; this file is the
# part that only minoris needs: where the weather is, the power profile for a
# machine that is not a laptop any more, and the kiosk session that puts a
# browser full-screen on the panel at boot.
#
# Nothing here is enabled by a host unless it lists `hjem` in its module set,
# which is why the greetd autologin below cannot surprise another machine.
{inputs, ...}: {
  unify.modules.hjem.nixos = {
    pkgs,
    lib,
    hostConfig,
    ...
  }: let
    inherit (hostConfig.user) username;

    port = 8080;
    url = "http://127.0.0.1:${toString port}";

    # Extra .ics feeds, merged with whatever Google returns. Empty by default;
    # the calendar proper comes from the API, so this is for the occasional
    # shared feed someone sends you. Lives in the state directory so adding one
    # is an edit and a restart rather than a rebuild.
    calendarFile = "/var/lib/hjem/calendars";

    calendarTemplate = pkgs.writeText "hjem-calendars" ''
      # Extra .ics feeds, one URL per line. Lines starting with # are ignored.
      # These are merged with the Google calendar; duplicates collapse.
      #
      # A *private* Google iCal address is a bearer credential -- anyone
      # holding the URL can read the calendar -- so if you put one here, note
      # that this file is only as private as its 0640 hjem:hjem permissions.
      # The OAuth path (modules/secrets/hjem.yaml) is the better answer.
      #
      # Then: sudo systemctl restart hjem
    '';

    # Chromium rather than Firefox: this page leans on canvas, and chromium's
    # is faster on the integrated graphics in a machine of this vintage.
    # --kiosk hides everything; the rest suppress the first-run, crash-restore
    # and translate furniture that would otherwise sit over the clock forever.
    browserFlags = lib.concatStringsSep " " [
      "--kiosk"
      "--ozone-platform=wayland"
      "--enable-features=UseOzonePlatform"
      "--noerrdialogs"
      "--no-first-run"
      "--no-default-browser-check"
      "--disable-infobars"
      "--disable-session-crashed-bubble"
      "--disable-features=Translate,TranslateUI,InfiniteSessionRestore"
      "--hide-scrollbars"
      "--overscroll-history-navigation=0"
      "--autoplay-policy=no-user-gesture-required"
      "--password-store=basic"
      "--check-for-update-interval=31536000"
    ];

    kiosk = pkgs.writeShellApplication {
      name = "hjem-kiosk";
      runtimeInputs = [pkgs.cage pkgs.chromium pkgs.curl pkgs.coreutils];
      text = ''
        # greetd stops the session by signalling this script; exit cleanly so
        # the greeter comes back rather than the restart loop below fighting it.
        trap 'exit 0' TERM INT

        profile="''${XDG_CACHE_HOME:-$HOME/.cache}/hjem-kiosk"
        mkdir -p "$profile"

        # Wait for the server rather than letting chromium cache a connection
        # error as the page. hjem is up in a second or two; 60 is for the case
        # where the network is not.
        for _ in $(seq 1 60); do
          if curl -fsS --max-time 2 ${url}/api/health >/dev/null 2>&1; then break; fi
          sleep 1
        done

        # Consecutive *immediate* exits mean something is actually broken (no
        # GPU, no seat, a bad flag). Restarting forever would hide that behind a
        # flickering black screen, so after five we stand down and let greetd
        # show a login prompt you can debug from.
        fails=0
        while true; do
          started=$(date +%s)

          # A leftover lock from a hard power cut makes chromium refuse to start.
          rm -f "$profile/Singleton"*

          cage -s -- chromium ${browserFlags} --user-data-dir="$profile" ${url} || true

          if [ $(( $(date +%s) - started )) -lt 15 ]; then
            fails=$(( fails + 1 ))
          else
            fails=0
          fi

          if [ "$fails" -ge 5 ]; then
            echo "hjem-kiosk: five immediate exits; handing back to greetd" >&2
            exit 1
          fi
          sleep 2
        done
      '';
    };
  in {
    imports = [inputs.hjem.nixosModules.hjem];

    # Calendar and tasks are OFF for now -- no Google keys to mint, nothing to
    # log in to. Everything they need is still here and still built; turning
    # them back on is this block plus the three options below it:
    #
    #   sops.secrets.hjem_google = {
    #     sopsFile = ../secrets/hjem.yaml;
    #     key = "google_credentials";
    #     owner = "hjem";
    #     group = "hjem";
    #     mode = "0400";
    #   };
    #
    # modules/secrets/hjem.yaml is already in the repo with a placeholder; run
    # `nix run github:malleum/hjem#google-auth` and `sops` it in. With no
    # calendar configured the panel simply drops the agenda card, so nothing
    # sits there reporting its own absence.

    services.hjem = {
      enable = true;
      inherit port;

      place = "Albany";

      # Celsius for temperature, imperial for everything else.
      temperatureUnit = "celsius";
      windUnit = "mph";
      precipitationUnit = "inch";

      # calendarEmail = "malleustempus@gmail.com";
      # inherit calendarFile;
      #
      # Calendar *and* tasks from one credential. The calendar stays private --
      # no shareable .ics URL exists for it -- and recurrence is expanded by the
      # API rather than by our own RRULE code. The tasks card is Google Tasks,
      # which is where Keep's reminders live; consumer Keep itself has no API.
      # googleCredentialsFile = config.sops.secrets.hjem_google.path;

      language = "eo";
      clock = "duod";
      fx = "full";

      # `lap` already turns on hardware.acpilight, which is what gives the
      # service's `video` group write access to the backlight.
      backlight = "auto";
      nightBrightness = 0.18;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/hjem 0750 hjem hjem -"
      # Seeded even while the calendar is off, so the file is there to edit the
      # day it goes back on.
      "C ${calendarFile} 0640 hjem hjem - ${calendarTemplate}"
    ];

    # cage is a wlroots compositor; without this there is no EGL and it exits
    # before chromium ever starts. minoris does not list the `amd` module, which
    # would otherwise have pulled it in.
    hardware.graphics.enable = true;

    # The `lap` TLP profile is tuned for a laptop in a bag. minoris is a wall
    # panel on mains power whose entire job is compositing a canvas, so the AC
    # side of that profile is undone here. The battery side is left exactly as
    # it was: unplugged, it should still behave like a laptop.
    #
    # The governor is the line that matters. `powersave` means "the normal
    # dynamic governor" under intel_pstate and amd_pstate in *active* mode --
    # but under acpi-cpufreq, which is what an AMD chip without CPPC gets, it
    # pins the core to its lowest frequency and leaves it there. This host is
    # AMD and does not carry the `amd` module, so it never gets the
    # amd_pstate=active kernel parameter. schedutil is right for every driver
    # that has it; where it is missing (pstate in active mode) TLP warns and
    # leaves the existing governor, which is already correct there. `ondemand`
    # is the fallback on a kernel without schedutil.
    #
    # CPU_MAX_PERF/ENERGY_PERF_POLICY only do anything under a pstate driver,
    # so on an older AMD part they are a no-op rather than the fix -- set
    # correctly for the case where they do apply.
    #
    # Check what this box actually has:
    #   cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
    #   cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
    #
    # mkForce because modules/hardware/battery.nix sets these for every `lap`
    # host; this module is imported by minoris alone, so nothing else moves.
    services.tlp.settings = {
      CPU_SCALING_GOVERNOR_ON_AC = lib.mkForce "schedutil";
      CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkForce "balance_performance";
      CPU_BOOST_ON_AC = lib.mkForce 1;
      CPU_MAX_PERF_ON_AC = lib.mkForce 100;
    };

    environment.systemPackages = [kiosk pkgs.cage pkgs.chromium];

    # initial_session logs straight into the panel at boot. default_session is
    # still tuigreet (modules/services/login_manager.nix), so quitting the kiosk
    # gives you a normal login and a normal session -- this is an autologin, not
    # a one-way door.
    services.greetd.settings.initial_session = {
      command = lib.getExe kiosk;
      user = username;
    };
  };
}
