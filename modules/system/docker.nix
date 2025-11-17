{
  unify.modules.doc.nixos =
    { hostConfig, ... }:
    {
      users.users.${hostConfig.user.username}.extraGroups = [ "docker" ];

      virtualisation.docker = {
        enable = true;
        # Set up resource limits
        daemon.settings = {
          experimental = true;
          default-address-pools = [
            {
              base = "172.30.0.0/16";
              size = 24;
            }
          ];
        };
      };
    };
}
