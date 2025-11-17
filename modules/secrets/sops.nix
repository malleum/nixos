{inputs, ...}: {
  unify.nixos = {hostConfig, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = ./default.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      secrets = {};
    };
  };

  unify.home = {hostConfig, ...}: {
    imports = [inputs.sops-nix.homeManagerModules.sops];
    sops = {
      defaultSopsFile = ./default.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      secrets = {
        spotify_client_id = {};
        github_token = {};
      };
    };
  };
}
