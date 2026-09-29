{
  flake.modules.nixos.base = {pkgs, ...}: {
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-curses;
      };
    };
  };
}
