{
  unify.modules.gui.nixos = {
    services.openssh.enable = true;

    # services.resolved.enable = true; # TODO: maybe for vpn
  };
}
