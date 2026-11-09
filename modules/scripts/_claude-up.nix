# claude-up: bump only the claude-code and claude-desktop flake inputs, switch,
# then commit and push flake.lock. Extra args go to `nh os switch`.
#
# Refuses to start if flake.lock already has uncommitted changes, so the commit
# only ever carries these two inputs. Afterwards it refreshes the jay bar count
# (claude-updates.service, manus only).
{pkgs}:
pkgs.writeShellApplication {
  name = "claude-up";
  runtimeInputs = with pkgs; [coreutils git jq nh systemd];
  text = ''
    cd "''${NH_FLAKE:-$HOME/.config/nixos}"

    if ! git diff --quiet HEAD -- flake.lock; then
      echo "claude-up: flake.lock has uncommitted changes; commit or discard them first" >&2
      exit 1
    fi

    # Short locked rev of a root input.
    rev() {
      jq -r --arg i "$1" '.nodes[.nodes.root.inputs[$i]].locked.rev[:7]' flake.lock
    }

    old_code=$(rev claude-code)
    old_desktop=$(rev claude-desktop)
    nix flake update claude-code claude-desktop
    new_code=$(rev claude-code)
    new_desktop=$(rev claude-desktop)

    if git diff --quiet HEAD -- flake.lock; then
      echo "claude-up: already up to date"
    else
      nh os switch "$@"

      msg="claude-up:"
      if [[ $old_code != "$new_code" ]]; then
        msg+=" claude-code $old_code -> $new_code,"
      fi
      if [[ $old_desktop != "$new_desktop" ]]; then
        msg+=" claude-desktop $old_desktop -> $new_desktop,"
      fi
      git commit -m "''${msg%,}" -- flake.lock
      git push
    fi

    systemctl --user start --no-block claude-updates.service 2>/dev/null || true
  '';
}
