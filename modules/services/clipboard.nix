{
  unify.modules.gui.nixos =
    { pkgs, ... }:
    {
      systemd.user.services = {
        cliphist = {
          description = "Clipboard manager";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
            Restart = "always";
            RestartSec = 3;
          };
        };
      };
    };
}
