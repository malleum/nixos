# Toggle a monitor on/off by EDID serial number.
#
#   jay-toggle-monitor <serial>
#
# `jay randr output` takes a connector, and connectors move between reboots
# (manus' left LG floats DP-1 <-> DP-2), so the connector is resolved from the
# serial at runtime.
#
# Two things got simpler once `jay --json` was used instead of scraping the
# human-readable output: the connector lookup no longer depends on jay's exact
# indentation (it was matching 6- and 8-space prefixes with awk), and the
# XDG_RUNTIME_DIR state file is gone entirely -- the JSON reports `enabled`
# per connector, so the real state is queryable and cannot desync from a
# tracking file.
#
# `jay` itself comes from the user profile, not runtimeInputs: it is the flake
# input's package, not a nixpkgs one, and this file is callPackage'd with {}.
{pkgs}:
pkgs.writeShellApplication {
  name = "jay-toggle-monitor";
  runtimeInputs = with pkgs; [jq libnotify];
  text = ''
    if [ $# -lt 1 ]; then
      echo "usage: jay-toggle-monitor <edid-serial>" >&2
      exit 2
    fi
    serial="$1"

    # `|| true` guards the whole pipeline: pipefail would otherwise abort here
    # on no-match, before the empty check below can report it nicely.
    info=$(
      jay --json randr show \
        | jq -r --arg s "$serial" '
            .drm_devices[].connectors[]
            | select(.output.serial_number == $s)
            | "\(.name) \(.enabled)"
          ' \
        | head -1
    ) || true

    if [ -z "$info" ]; then
      notify-send -t 2000 "Monitor" "serial $serial not found"
      exit 1
    fi

    conn="''${info%% *}"
    enabled="''${info##* }"

    if [ "$enabled" = "true" ]; then
      jay randr output "$conn" disable
      notify-send -t 1500 "Monitor ($conn)" "disabled"
    else
      jay randr output "$conn" enable
      notify-send -t 1500 "Monitor ($conn)" "enabled"
    fi
  '';
}
