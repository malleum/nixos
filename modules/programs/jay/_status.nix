# The i3bar status feed for jay: a small Rust program (_status.rs) that shares
# the duod clock code in modules/scripts/_daytime.rs. Only the theme colours
# and the pactl path are generated here.
{
  pkgs,
  colors,
}: let
  const = name: value: ''const ${name}: &str = "${value}";'';
in
  pkgs.writers.writeRustBin "jay-status" {} (builtins.concatStringsSep "\n" [
    (builtins.readFile ../../scripts/_daytime.rs)
    (const "PACTL" "${pkgs.pulseaudio}/bin/pactl")
    # Per-block accent colours. Only the icon is coloured; values keep jay's
    # bar-status-text-color for readability.
    (const "C_AUDIO" "#${colors.base0C}")
    (const "C_BT" "#${colors.base0B}")
    (const "C_CPU" "#${colors.base0D}")
    (const "C_MEM" "#${colors.base0E}")
    (const "C_DISK" "#${colors.base09}")
    (const "C_BAT" "#${colors.base0B}")
    (const "C_BAT_LOW" "#${colors.base08}")
    (const "C_DATE" "#${colors.base0A}")
    (const "C_DUOD" "#${colors.base0F}")
    (const "C_DIM" "#${colors.base03}")
    (const "C_BG" "#${colors.base01}") # bar background, for the invisible spacer
    (const "C_PILL" "#${colors.base02}") # pill fill, one shade above the bar
    (builtins.readFile ./_status.rs)
  ])
