# Core desktop only: the things a graphical session is broken without.
# Editors/toolchains -> dev, players/editors -> med, documents -> off,
# the GlobalProtect client -> wrk.
{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      networkmanagerapplet

      pavucontrol
      pulsemixer

      nwg-look
      gtk4
      gtk3
    ];
  };
}
