# swayosd-client wrapper that pins the popup to the focused output.
#
#   jay-osd --output-volume raise
#
# swayosd draws a layer surface on *every* output (verified: one extra surface
# per output while the OSD is up), so on a three-monitor desktop the volume
# popup appears three times. It accepts --monitor to pin it, but that needs the
# name of the output you are actually looking at.
#
# jay's tree does not mark focus. wlr-foreign-toplevel does: exactly one
# toplevel carries the `activated` state. So resolve the focused window through
# wlrctl, then find which output's subtree contains it.
#
# Layer surfaces are per-output, not per-workspace -- they float above whichever
# workspace that output is currently showing -- so pinning to the focused output
# is what "only on the active workspace" actually means here.
#
# jay and wlrctl come from the user profile: jay is the flake input's package,
# and wlrctl needs the [[clients]] foreign-toplevel-manager grant from
# jay/_config.nix, which is keyed on comm.
{pkgs}:
pkgs.writeShellApplication {
  name = "jay-osd";
  runtimeInputs = with pkgs; [jq swayosd];
  text = ''
    monitor=""

    # "app_id: title" of the one toplevel in the activated state.
    line=$(wlrctl toplevel list state:activated 2>/dev/null | head -1) || true

    if [ -n "$line" ]; then
      app_id="''${line%%:*}"
      title="''${line#*: }"
      monitor=$(
        jay --json tree query -r root 2>/dev/null \
          | jq -r --arg a "$app_id" --arg t "$title" '
              .children[] | select(.type=="output") | .output as $name
              | if [.. | objects | select(.app_id==$a and .title==$t)] | length > 0
                then $name else empty end
            ' \
          | head -1
      ) || true
    fi

    # No focused window (empty workspace) means no output to pin to; fall back
    # to swayosd's default of every output rather than showing nothing.
    if [ -n "$monitor" ]; then
      exec swayosd-client --monitor "$monitor" "$@"
    else
      exec swayosd-client "$@"
    fi
  '';
}
