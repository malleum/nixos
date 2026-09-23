# Shared shape for a jay session user unit.
#
# Lives on its own because both the compositor module and the chat module
# declare units bound to jay-session.target, and duplicating the wiring would
# invite the two copies to drift.
{
  lib,
  pkgs,
}: {
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
  # Stamp name under $XDG_RUNTIME_DIR/jay-session-apps. With it the unit starts
  # at most once per session. `guard` alone cannot express this: quitting the
  # app leaves the unit inactive (iamb exits 1, so actually failed) with no
  # process for pgrep to find, which is exactly the state sd-switch starts --
  # so every `nh os switch` reopened a window that had been closed on purpose,
  # typically in favour of the GUI client. The stamp is written on start and
  # outlives the process, so it is the only record that the app was already
  # offered this session. Jay clears the directory before starting the target
  # (see _config.nix on-graphics-initialized), and the keybinding that opens
  # the app clears its own stamp first, so deliberate reopens still work.
  once ? null,
}: let
  stampDir = "\${XDG_RUNTIME_DIR}/jay-session-apps";
  stamp = "${stampDir}/${toString once}";
  onceGuard = "${pkgs.bash}/bin/bash -c '! [ -e \"${stamp}\" ]'";
  onceStamp = "${pkgs.bash}/bin/bash -c 'mkdir -p \"${stampDir}\" && touch \"${stamp}\"'";
  conditions = lib.optional (guard != null) guard ++ lib.optional (once != null) onceGuard;
in {
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
    // (lib.optionalAttrs (conditions != []) {ExecCondition = conditions;})
    // (lib.optionalAttrs (once != null) {ExecStartPost = onceStamp;})
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
