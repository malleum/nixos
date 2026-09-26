# hjem (github:malleum/hjem) -- the wall panel. A duodecimal ring clock, the
# weather, a verse of the day in Esperanto that translates itself one phrase
# per dwell through the afternoon, an Esperanto root a day with the words the
# corpus builds out of it, and a background that answers the sky: the real
# stars and planets over Easley when it is clear, and an aurora when NOAA says
# the oval has come far enough south to be worth walking outside for. All on an
# old 12" Dell that does nothing else.
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

    # The webcam, doing two jobs (see hjem's web/js/camera.js):
    #
    #   presence    at night, bring the backlight up while someone is standing
    #               in front of the panel, and let it fall when the room empties
    #   lightMeter  whenever the room is dark -- lights off, curtains drawn --
    #               dim the panel to darkRoomBrightness
    #
    # On, both. The dark-room dimming is what makes a wall panel livable in a
    # bedroom, and presence is what makes a dimmed one readable when you walk
    # up to it; each is a little strange without the other.
    #
    # The flag is what makes the camera usable at all -- getUserMedia would
    # otherwise raise a permission prompt that nobody is standing there to
    # answer, and a kiosk has no chrome to answer it with. It grants camera
    # access to whatever the browser loads, which here is one page on
    # 127.0.0.1 and nothing else, for the life of the session. Opening
    # /dev/video0 itself is covered by `video` in modules/meta/user.nix.
    #
    # What leaves the page: an empty POST when something moves, and one number
    # -- the mean brightness of a 48x36 grey frame -- for the light meter. No
    # image is stored or sent anywhere. The camera LED is on while the panel is
    # dark, and for a few seconds every ten minutes in daylight while it takes
    # a reading; otherwise off.
    presence = true;
    lightMeter = true;

    presenceFlags = lib.optional (presence || lightMeter) "--use-fake-ui-for-media-stream";

    # Chromium rather than Firefox: this page leans on canvas, and chromium's
    # is faster on the integrated graphics in a machine of this vintage.
    # --kiosk hides everything; the rest suppress the first-run, crash-restore
    # and translate furniture that would otherwise sit over the clock forever.
    browserFlags = lib.concatStringsSep " " (presenceFlags
      ++ [
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
      ]);

    kiosk = pkgs.writeShellApplication {
      name = "hjem-kiosk";
      runtimeInputs = [pkgs.cage pkgs.chromium pkgs.curl pkgs.coreutils pkgs.systemd];
      text = ''
        # greetd stops the session by signalling this script; exit cleanly so
        # the greeter comes back rather than the restart loop below fighting it.
        trap 'exit 0' TERM INT

        # Everything this script and cage say goes to the journal under one tag,
        # because a greetd session's stderr otherwise goes nowhere you can read
        # afterwards:  journalctl -b -t hjem-kiosk
        # `|| true` because this runs under errexit, and a journal that is not up
        # yet must not be what takes the panel down.
        say() { echo "$*" | systemd-cat -t hjem-kiosk -p info || true; }

        profile="''${XDG_CACHE_HOME:-$HOME/.cache}/hjem-kiosk"
        mkdir -p "$profile"

        # amdgpu loads from udev in stage 2, and greetd can get here first. With
        # no /dev/dri/card* cage has nothing to open and exits at once -- five of
        # those and this script used to give up before the GPU ever arrived.
        for _ in $(seq 1 60); do
          if compgen -G "/dev/dri/card*" >/dev/null; then break; fi
          sleep 1
        done
        compgen -G "/dev/dri/card*" >/dev/null || say "no DRM device after 60s; trying anyway"

        # Wait for the server rather than letting chromium cache a connection
        # error as the page -- chromium does not retry an error page on its own,
        # so a panel that loaded too early would show "site can't be reached"
        # until someone walked up with a keyboard. hjem no longer waits for the
        # network before it listens, so this is normally a second or two.
        for _ in $(seq 1 180); do
          if curl -fsS --max-time 2 ${url}/api/health >/dev/null 2>&1; then break; fi
          sleep 1
        done

        # Consecutive *immediate* exits mean something is actually broken (no
        # GPU, no seat, a bad flag). Two in a row and the next attempts use
        # wlroots' software renderer: a panel drawn slowly beats a black one,
        # and it is the difference between "the GPU driver is unhappy" and "the
        # machine is dead" when you are looking at it from across a room. Five
        # and we stand down, so greetd shows a login prompt to debug from.
        fails=0
        while true; do
          started=$(date +%s)

          # A leftover lock from a hard power cut makes chromium refuse to start.
          rm -f "$profile/Singleton"*

          if [ "$fails" -ge 2 ]; then
            export WLR_RENDERER=pixman
            say "attempt after $fails fast exits: software rendering"
          fi

          cage -s -- chromium ${browserFlags} --user-data-dir="$profile" ${url} \
            2> >(systemd-cat -t hjem-kiosk -p warning) || true

          if [ $(( $(date +%s) - started )) -lt 15 ]; then
            fails=$(( fails + 1 ))
            say "cage exited after $(( $(date +%s) - started ))s ($fails in a row)"
          else
            fails=0
          fi

          if [ "$fails" -ge 5 ]; then
            say "five immediate exits; handing back to greetd"
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

      # Explicit coordinates rather than `place = "Easley"`: there are Easleys
      # in Alabama, Missouri and Iowa, and more to the point the sky scene
      # draws the actual sky from these numbers, so the panel should not have
      # to reach the geocoder before it knows where it is standing.
      latitude = "34.82984";
      longitude = "-82.60152";
      place = "Easley";

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

      # The countdown inside the ring, in the clock's own units. The panel
      # shows the soonest of these and moves on to the next as each passes, so
      # this is a chain rather than a list: Taiwan, then Christmas, then
      # Easter, and from there Christmas and Easter alternate on their own for
      # as long as the panel is on the wall.
      #
      # Taiwan is a dated one-off and drops out once it is behind us. The other
      # two recur -- `easter` is computed each year rather than written down,
      # which is the only reason server/events.py contains a computus.
      #
      # Add `until = "2026-11-…";` to the Taiwan entry and the panel will count
      # the trip down to its end once it has started, instead of moving
      # straight on to Christmas on the morning of the 1st.
      events = [
        {
          name = "Taiwan";
          nameEo = "Tajvano";
          on = "2026-10-31";
        }
        {
          name = "Christmas";
          nameEo = "Kristnasko";
          on = "12-25";
        }
        {
          name = "Easter";
          nameEo = "Pasko";
          on = "easter";
        }
      ];

      language = "eo";
      clock = "duod";
      fx = "full";

      # `lap` already turns on hardware.acpilight, which is what gives the
      # service's `video` group write access to the backlight.
      backlight = "auto";
      nightBrightness = 0.18;

      # The other half of the camera switches at the top of this file. The
      # palette stays in its night amber either way -- the point is to be
      # readable in a dark room, not to light the room.
      #
      # The dark-room threshold is a guess until it has seen this room. The
      # footer shows what the meter reads as "ĉambro N": look at it with the
      # lights on and with them off, and set darkRoomLevel between the two.
      inherit presence lightMeter;
      darkRoomLevel = 40.0;
      darkRoomBrightness = 0.06;
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

    # Undo the silent console that modules/services/login_manager.nix asks for.
    # There, `quiet` plus loglevel 0 exists so that late-boot kernel and unit
    # output does not paint over the tuigreet form; here the kiosk covers the
    # screen the moment it starts, so there is nothing to protect -- and the
    # screen is the only diagnostic this machine has. A panel with no keyboard
    # in front of it that shows absolutely nothing for the length of a boot
    # cannot be told apart from one that failed to boot, which is how a slow
    # boot gets power-cycled halfway through. Let it narrate.
    #
    # 4 is KERN_WARNING: warnings and errors from the kernel, not the full
    # amdgpu firmware dump. It lands after `quiet` on the kernel command line,
    # so it wins -- for the kernel.
    #
    # That was only half of it, and the photo of the boot shows which half:
    # four kernel lines and then nothing. The unit lines come from systemd, not
    # the kernel, and systemd reads `quiet` too -- per systemd(1) in 261,
    # show_status "defaults to enabled, unless quiet is passed ... in which case
    # it defaults to error". So loglevel alone gave the kernel its voice back and
    # left PID 1 printing failures only. Setting show_status explicitly
    # overrides the quiet-derived default regardless of where it sits on the
    # command line; the rd. form is the same switch for the initrd's systemd.
    boot.consoleLogLevel = lib.mkForce 4;
    boot.initrd.verbose = lib.mkForce true;
    boot.kernelParams = [
      "systemd.show_status=true"
      "rd.systemd.show_status=true"
    ];

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
