# Shared shape for a jay session user unit.
#
# Lives on its own because both the compositor module and the chat module
# declare units bound to jay-session.target, and duplicating the wiring would
# invite the two copies to drift.
{lib}: {
  description,
  exec,
  # Daemons restart on failure and on switch. Apps (things merely launched at
  # login) do neither: respawning something you deliberately quit is a bug, and
  # X-SwitchMethod=keep-old stops home-manager's sd-switch tearing the window
  # down and reopening it on every `nh os switch`.
  #
  # keep-old only covers a unit that is *active* at switch time. sd-switch also
  # starts anything WantedBy an active target that is currently inactive, so a
  # copy spawned outside systemd (or one whose unit died while the window
  # lived) got a second window on every switch. `guard` is an ExecCondition:
  # nonzero exit makes systemd skip the start cleanly, without marking the unit
  # failed. RefuseManualStart is NOT the answer here -- sd-switch stops the old
  # unit and is then refused the start, leaving the app dead.
  restart ? true,
  # Shell test run before ExecStart; false (nonzero) means "already running,
  # do nothing".
  guard ? null,
}: {
  Unit =
    {
      # Capital D -- raw systemd INI keys, not nix options. A lowercase
      # `description` is silently ignored and the unit ends up named after its
      # own filename in systemctl output.
      Description = description;
      PartOf = ["jay-session.target"];
      After = ["jay-session.target"];
    }
    // (lib.optionalAttrs (!restart) {X-SwitchMethod = "keep-old";});

  Service =
    {ExecStart = exec;}
    // (lib.optionalAttrs (guard != null) {ExecCondition = guard;})
    // (
      if restart
      then {
        Restart = "always";
        RestartSec = 2;
      }
      else {Restart = "no";}
    );

  Install.WantedBy = ["jay-session.target"];
}
