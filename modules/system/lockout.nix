# Nine wrong passwords, then a five-minute wait before the next nine.
#
# On the lock screen and on login alike (greetd and the TTYs both go through
# `login`), with one shared count: otherwise a reboot, which lands on greetd,
# would be the way around the lock screen's limit.
#
# Locked out by a stuck key? Wait, or ssh in with a key and run
#   sudo faillock --user "$USER" --reset
{
  flake.modules.nixos.gui = {
    lib,
    pkgs,
    ...
  }: let
    limit = nodelay:
      import ./_faillock.nix {inherit lib pkgs;} {
        inherit nodelay;
        deny = 9;
        unlockTime = 300;
      };
  in {
    security.pam.services = {
      login.rules.auth = limit false;
      # No two-second sleep after a wrong password on the lock screen (one
      # switch for pam_unix, one for pam_faillock). The limit is the brake now.
      swaylock = {
        rules.auth = limit true;
        nodelay = true;
      };
    };
  };
}
