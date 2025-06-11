{pkgs, ...}: {
  # Create the config file manually
  environment.etc."keyd/default.conf".text = ''
    [ids]
    *

    [main]
    capslock = esc
  '';

  # Create a working systemd service
  systemd.services.keyd-manual = {
    description = "keyd remapping daemon";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.keyd}/bin/keyd";
      Restart = "always";
      RestartSec = 1;

      # Keep it simple - run as root, don't try to change groups
      User = "root";

      # Don't restrict capabilities that keyd might need
      NoNewPrivileges = false;

      # Allow keyd to do what it needs
      ProtectSystem = false;
      ProtectHome = false;
    };
  };
  users.groups.keyd = {};
}
