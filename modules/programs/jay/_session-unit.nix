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
  restart ? true,
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
