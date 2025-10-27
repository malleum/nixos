{
  unify.home = {config, ...}: {
    programs.git = {
      enable = true;
      settings = {
        user = {inherit (config) email name;};
        push.autoSetupRemote = true;
      };
    };
  };
}
