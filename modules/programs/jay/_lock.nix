# The lock screen.
#
# swaylock-effects rather than plain swaylock: same PAM service ("swaylock",
# which NixOS ships by default) and the same binary name, so the [[clients]]
# rule in _config.nix that grants session-lock still matches, but it can draw
# a clock, an indicator ring and a background image.
#
# Deliberately *not* --screenshots / --effect-blur: a blurred screenshot still
# shows the shape and colour of whatever was on screen. The wallpaper is used
# as the background instead, so a locked screen leaks nothing about the
# session while still looking like the rest of the theme.
{
  pkgs,
  colors,
  wallpaper,
}:
pkgs.writeShellApplication {
  name = "jay-lock";
  runtimeInputs = [pkgs.swaylock-effects];
  text = ''
    exec swaylock \
      --image "${wallpaper}" \
      --scaling fill \
      --effect-vignette 0.4:0.6 \
      --clock \
      --timestr "%H:%M" \
      --datestr "%A, %B %-d" \
      --font "JetBrainsMono Nerd Font" \
      --indicator \
      --indicator-radius 110 \
      --indicator-thickness 8 \
      --indicator-idle-visible \
      --fade-in 0.2 \
      --color "${colors.base00}" \
      --inside-color "${colors.base00}CC" \
      --inside-ver-color "${colors.base00}CC" \
      --inside-wrong-color "${colors.base00}CC" \
      --inside-clear-color "${colors.base00}CC" \
      --ring-color "${colors.base0D}" \
      --ring-ver-color "${colors.base0C}" \
      --ring-wrong-color "${colors.base08}" \
      --ring-clear-color "${colors.base0A}" \
      --key-hl-color "${colors.base0B}" \
      --bs-hl-color "${colors.base08}" \
      --text-color "${colors.base05}" \
      --text-ver-color "${colors.base05}" \
      --text-wrong-color "${colors.base08}" \
      --text-clear-color "${colors.base05}" \
      --separator-color "#00000000" \
      --line-color "#00000000" \
      "$@"
  '';
}
