{inputs, ...}: {
  unify.nixos = {hostConfig, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      secrets = {
        spotify_client_id = {
          sopsFile = ./default.yaml;
          key = "spotify_client_id";
        };
        github_token = {
          sopsFile = ./default.yaml;
          key = "github_token";
        };
      };
    };
  };
}
