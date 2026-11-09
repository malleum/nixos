# claude-updates: how many releases the locked claude-code and claude-desktop
# flake inputs are behind upstream, i.e. what `claude-up` would pull in.
#
# Counts the version-bump commits between the locked rev and the default
# branch (GitHub compare API, unauthenticated: 60 requests/hour, two per run).
#
#   claude-updates         print "claude-code N" / "claude-desktop N"
#   claude-updates --bar   also write "N M" to $XDG_RUNTIME_DIR/claude-updates
#                          for the jay-status pill. A failed lookup keeps that
#                          input's previous count.
{pkgs}:
pkgs.writeShellApplication {
  name = "claude-updates";
  runtimeInputs = with pkgs; [coreutils curl jq];
  text = ''
    lock="''${NH_FLAKE:-$HOME/.config/nixos}/flake.lock"
    cache="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-updates"

    # behind <input> <commit-subject regex>: release commits since the locked rev.
    behind() {
      local repo rev
      read -r repo rev < <(jq -r --arg i "$1" \
        '.nodes[.nodes.root.inputs[$i]].locked | "\(.owner)/\(.repo) \(.rev)"' "$lock")
      curl -fsS --max-time 20 "https://api.github.com/repos/$repo/compare/$rev...HEAD" \
        | jq --arg re "$2" '[.commits[].commit.message | select(test($re; "i"))] | length'
    }

    old_code="?"
    old_desktop="?"
    if [[ -f $cache ]]; then
      read -r old_code old_desktop < "$cache" || true
    fi

    code=$(behind claude-code '^chore: update claude-code to version') || code=$old_code
    desktop=$(behind claude-desktop '^update claude desktop to version') || desktop=$old_desktop

    echo "claude-code $code"
    echo "claude-desktop $desktop"
    if [[ ''${1-} == --bar ]]; then
      echo "$code $desktop" > "$cache.tmp"
      mv "$cache.tmp" "$cache"
    fi
  '';
}
