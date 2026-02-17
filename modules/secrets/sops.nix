{inputs, ...}: {
  unify.nixos = {hostConfig, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = ./default.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      secrets = {
        github_token = {};
      };
    };
  };

  unify.home = {hostConfig, ...}: {
    imports = [inputs.sops-nix.homeManagerModules.sops];
    sops = {
      defaultSopsFile = ./default.yaml;
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      secrets = {
        spotify_client_id = {};
        github_token = {};
        oracle_ssh_private = {
          sopsFile = ./oracle-ssh.yaml;
          key = "private_key";
          path = "${hostConfig.user.homeDirectory}/.ssh/oracle";
        };
        vs_gitlab_private = {
          sopsFile = ./vs-gitlab.yaml;
          key = "private_key";
          path = "${hostConfig.user.homeDirectory}/.ssh/vs_gitlab";
        };
      };
    };

    programs.ssh = {
      extraConfig = ''
        Host oracle minimus
          IdentityFile ${hostConfig.user.homeDirectory}/.ssh/oracle
      '';
    };
  };
}
