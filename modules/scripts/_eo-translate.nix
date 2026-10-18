# Esperanto -> English lookup in rofi, bound to super-shift-t in jay.
#
# Uses the endpoint Google's Chrome translate extension talks to: no API key,
# and unlike translate.googleapis.com/translate_a/single (what translate-shell
# uses) it is not quick to answer with a "sorry, automated queries" page.
#
# Typing x-system is accepted (cx -> ĉ, sx -> ŝ, ux -> ŭ, ...), since x is not
# an Esperanto letter. The prompt reopens with the last result shown, so
# several words can be looked up in a row; Escape or an empty entry quits. The
# last translation is left on the clipboard.
{pkgs}:
pkgs.writeShellApplication {
  name = "eo-translate";
  runtimeInputs = with pkgs; [curl jq wl-clipboard];
  text = ''
    mesg="Esperanto → English (x-system ok: cx, gx, sx, ux…)"
    while :; do
      query=$(rofi -dmenu -p eo -mesg "$mesg" -theme-str 'window {width: 50%;} listview {lines: 0;}' < /dev/null) || exit 0
      [ -n "$query" ] || exit 0

      query=$(printf '%s' "$query" | sed \
        -e 's/cx/ĉ/g; s/gx/ĝ/g; s/hx/ĥ/g; s/jx/ĵ/g; s/sx/ŝ/g; s/ux/ŭ/g' \
        -e 's/C[xX]/Ĉ/g; s/G[xX]/Ĝ/g; s/H[xX]/Ĥ/g; s/J[xX]/Ĵ/g; s/S[xX]/Ŝ/g; s/U[xX]/Ŭ/g')

      if result=$(curl -sf --max-time 5 --get 'https://clients5.google.com/translate_a/t' \
          -d client=dict-chrome-ex -d sl=eo -d tl=en \
          --data-urlencode "q=$query" | jq -er '.[0]'); then
        printf '%s' "$result" | wl-copy
        mesg="$query → $result"
      else
        mesg="$query → (lookup failed)"
      fi
      # rofi -mesg is pango markup
      mesg=$(printf '%s' "$mesg" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    done
  '';
}
