{
  unify.home = {hostConfig, config, ...}: {
    programs.git = {
      enable = true;
      settings = {
        user = {inherit (hostConfig.user) email name;};
        push.autoSetupRemote = true;
      };
    };

    programs.gh.enable = true;

    home.file."${hostConfig.user.configHome}/gh/hosts.yml" = {
      text = ''
        github.com:
              user: ${hostConfig.user.gitusername}
              oauth_token: ${config.sops.secrets.github_token.path}
      '';
    };
  };
}
