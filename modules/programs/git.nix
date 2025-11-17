{
  unify.home =
    {
      hostConfig,
      config,
      ...
    }:
    {
      programs.git = {
        enable = true;
        settings = {
          user = { inherit (hostConfig.user) email name; };
          push.autoSetupRemote = true;
        };
      };

      programs.gh.enable = true;

      sops.templates."gh-hosts" = {
        path = "${hostConfig.user.configHome}/gh/hosts.yml";
        content = ''
          github.com:
              users:
                  ${hostConfig.user.gitusername}:
                      oauth_token: ${config.sops.placeholder.github_token}
              git_protocol: https
              oauth_token: ${config.sops.placeholder.github_token}
              user: ${hostConfig.user.gitusername}
        '';
      };
    };
}
