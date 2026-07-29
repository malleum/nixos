{
  unify.nixos = {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        # Nothing needs an interactive root session: joshammer is in wheel and
        # wheelNeedsPassword is off, so `ssh <host>` + sudo covers admin work.
        PermitRootLogin = "no";
      };
    };
  };
}
