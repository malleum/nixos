{
  inputs,
  lib,
  ...
}: {
  unify.nixos = {hostConfig, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = ./default.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      # Minimus uses authorizedKeys.keys (literal) to avoid /run path at build time
      secrets = {};
    };
  };

  unify.home = {
    hostConfig,
    lib,
    ...
  }: {
    imports = [inputs.sops-nix.homeManagerModules.sops];
    sops = {
      defaultSopsFile = ./default.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "${hostConfig.user.configHome}/sops/age/keys.txt";

      secrets =
        {
          spotify_client_id = {};
          github_token = {};
        }
        // lib.optionalAttrs (hostConfig.name != "minimus") {
          oracle_ssh_private = {
            sopsFile = ./oracle-ssh.yaml;
            key = "private_key";
            path = "${hostConfig.user.homeDirectory}/.ssh/oracle";
          };
        };
    };

    programs.ssh = lib.mkIf (hostConfig.name != "minimus") {
      extraConfig = ''
        Host oracle minimus
          IdentityFile ${hostConfig.user.homeDirectory}/.ssh/oracle
      '';
    };
  };
}
