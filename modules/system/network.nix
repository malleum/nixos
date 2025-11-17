{
  unify.nixos =
    { hostConfig, ... }:
    {
      networking.networkmanager.enable = true;

      users.users.${hostConfig.user.username}.extraGroups = [ "networkmanager" ];
    };
}
