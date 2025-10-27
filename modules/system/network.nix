{
  unify.modules.laptop.nixos = {config, ...}: {
    networking.networkmanager.enable = true;

    users.users.${config.user.username}.extraGroups = ["networkmanager"];
  };
}
