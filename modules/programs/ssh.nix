# Client-side SSH config.
#
# This used to be a hand-written ~/.ssh/config plus a programs.ssh.extraConfig
# block in secrets/sops.nix that never applied -- home-manager only writes the
# file when programs.ssh.enable is true, which it wasn't. So the keys were
# managed declaratively (sops-nix drops them at ~/.ssh/oracle and
# ~/.ssh/vs_gitlab) while the config that points at them was not. Both halves
# live here now, sharing the same path values.
{
  unify.home = {hostConfig, ...}: let
    inherit (hostConfig.user) homeDirectory;

    oracleKey = "${homeDirectory}/.ssh/oracle";
    gitlabKey = "${homeDirectory}/.ssh/vs_gitlab";
  in {
    programs.ssh = {
      enable = true;

      # home-manager's implicit "*" block is on its way out; opt out and state
      # the defaults we actually want instead of inheriting whatever it picks.
      enableDefaultConfig = false;

      settings = {
        "*" = {
          controlMaster = "auto";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "10m";
          serverAliveInterval = 60;
        };

        # Oracle Cloud box: minimus is the flake host name, oracle the alias.
        "minimus oracle" = {
          hostname = "158.101.121.4";
          user = hostConfig.user.username;
          identityFile = oracleKey;
          identitiesOnly = true;
        };

        "gitlab.visiostack.com" = {
          user = "git";
          identityFile = gitlabKey;
          identitiesOnly = true;
        };
      };
    };
  };
}
