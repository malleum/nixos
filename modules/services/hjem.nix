# hjem (github:malleum/hjem) -- the wall panel. A duodecimal ring clock, the
# weather, and the next thing on the calendar, drawn on an old 12" Dell that
# does nothing else.
#
# The app's own flake carries the server and its NixOS module; this file is the
# part that only minoris needs: which calendar, where the weather is, and the
# kiosk session that puts a browser full-screen on the panel at boot.
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

    # Where a *private* Google iCal address goes. It is a bearer credential --
    # anyone holding the URL can read the calendar -- so it lives in the
    # service's state directory rather than in the world-readable Nix store.
    # Drop the URL in, `systemctl restart hjem`, done. No rebuild, no secret in
    # git. (sops-nix would also work; it is not worth a key rotation for one
    # URL on one host.)
    calendarFile = "/var/lib/hjem/calendars";

    calendarTemplate = pkgs.writeText "hjem-calendars" ''
      # One .ics URL per line. Lines starting with # are ignored.
      #
      # These replace services.hjem.calendars entirely once there is one here,
      # so the public URL below stops being fetched the moment you add the
      # private one.
      #
      # Google Calendar -> Settings -> Settings for my calendars -> <calendar>
      # -> Integrate calendar -> "Secret address in iCal format".
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

    services.hjem = {
      enable = true;
      inherit port;

      place = "Albany";

      # Celsius for temperature, imperial for everything else.
      temperatureUnit = "celsius";
      windUnit = "mph";
      precipitationUnit = "inch";

      calendarEmail = "malleustempus@gmail.com";
      inherit calendarFile;
      # Works only if the calendar is public; the file above is the real answer.
      calendars = [
        "https://calendar.google.com/calendar/ical/malleustempus%40gmail.com/public/basic.ics"
      ];

      clock = "duod";
      fx = "full";

      # `lap` already turns on hardware.acpilight, which is what gives the
      # service's `video` group write access to the backlight.
      backlight = "auto";
      nightBrightness = 0.18;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/hjem 0750 hjem hjem -"
      "C ${calendarFile} 0640 hjem hjem - ${calendarTemplate}"
    ];

    # cage is a wlroots compositor; without this there is no EGL and it exits
    # before chromium ever starts. minoris does not list the `amd` module, which
    # would otherwise have pulled it in.
    hardware.graphics.enable = true;

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
