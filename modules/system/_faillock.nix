# The auth rules that put a failed-attempt limit on a PAM service.
#
# `deny` wrong passwords lock the account for `unlockTime` seconds. While
# locked, the correct password is refused as well. A correct password, or
# `faillock --user NAME --reset` as root, clears the count.
#
# When the wait is over the count starts again from zero: it is `deny` tries
# per `unlockTime`, NOT one try per wait after the first lockout. pam_faillock
# forgets the old failures the moment it unlocks, and has no setting for
# anything stricter (checked in a VM, 2026-11-11).
#
# fail_interval is a day rather than the default 15 minutes, so slow guessing
# (a few tries an hour) still adds up to a lockout.
#
# This is the stack from pam_faillock(8). NixOS's own pam_unix rule is
# `sufficient`, which returns on success before anything after it runs, so the
# count would never be cleared; it becomes a "skip the next rule on success"
# jump instead, and the two rules it jumps over/onto must sit directly behind
# it. Where "it" is depends on the service: with pam_gnome_keyring (or any
# other module that wants the password) NixOS moves the deciding pam_unix rule
# from 11700 to 13100 and puts an optional "unix-early" at 11700. Hence
# `unixOrder`, read from the service itself. Getting this wrong puts authfail
# behind unix-early, where it fails every login.
#
# The tally lives in /run/faillock, one file per user, shared by every service
# that uses these rules. It does not survive a reboot.
{
  lib,
  pkgs,
}: {
  deny,
  unlockTime,
  # config.security.pam.services.<name>.rules.auth.unix.order
  unixOrder,
  # pam_faillock sleeps about two seconds after a wrong password, on top of
  # pam_unix's own delay (the service's `nodelay` option). True drops this one.
  nodelay ? false,
}: let
  rule = order: control: mode: {
    inherit order control;
    modulePath = "${pkgs.linux-pam}/lib/security/pam_faillock.so";
    args = [mode "deny=${toString deny}" "unlock_time=${toString unlockTime}" "fail_interval=86400"] ++ lib.optional nodelay "nodelay";
  };
in {
  # 11690 is ahead of both pam_unix rules: when locked, refuse before asking.
  faillock-preauth = rule 11690 "requisite" "preauth";
  unix.control = lib.mkForce "[success=1 default=bad]";
  faillock-authfail = rule (unixOrder + 1) "[default=die]" "authfail"; # wrong: count it
  faillock-authsucc = rule (unixOrder + 2) "sufficient" "authsucc"; # right: clear the count
}
