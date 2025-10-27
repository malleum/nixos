{
  unify.home = {hostConfig, ...}: {
    programs.git = {
      enable = true;
      settings = {
        user = {inherit (hostConfig.user) email name;};
        push.autoSetupRemote = true;
      };
    };
  };
}
