# Mystic Light (board), GPU and RAM RGB all come up lit. The openrgb server owns
# the i2c/USB devices; a oneshot then blanks everything through it at boot.
{pkgs, ...}: {
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  systemd.services.rgb-off = {
    description = "Turn off all RGB lighting";
    after = ["openrgb.service"];
    requires = ["openrgb.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      # the server needs a few seconds to finish device detection
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      ExecStart = "${pkgs.openrgb}/bin/openrgb --client 127.0.0.1:6742 --mode static --color 000000";
    };
  };

  # Suspend drops power to the controllers and they resume lit, so blank them
  # again on the way back up. The server is restarted first in case its
  # handles to the re-enumerated USB/i2c devices went stale over the sleep.
  # (WantedBy+After suspend.target = runs once resume has finished.)
  systemd.services.rgb-off-resume = {
    description = "Turn RGB lighting back off after resume";
    wantedBy = ["suspend.target"];
    after = ["suspend.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.systemd}/bin/systemctl restart openrgb.service"
        "${pkgs.systemd}/bin/systemctl start rgb-off.service"
      ];
    };
  };
}
