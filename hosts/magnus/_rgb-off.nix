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
}
