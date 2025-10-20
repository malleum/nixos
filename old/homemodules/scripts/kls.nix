{pkgs, ...}: let
  xkbmap = "${pkgs.xorg.setxkbmap}/bin/setxkbmap";
  rg = "${pkgs.ripgrep}/bin/rg";
in
  pkgs.writeShellScriptBin "kls" ''
    if [[ ! $(ps -e | ${rg} Xwayland) ]]; then
      var=$(${xkbmap} -query | ${rg} variant)
      if [[ $var == *"dvorak"* ]]; then
        ${xkbmap} -layout us
      else
        ${xkbmap} -variant dvorak
      fi
    else
      hyprctl switchxkblayout at-translated-set-2-keyboard next
    fi
  ''
