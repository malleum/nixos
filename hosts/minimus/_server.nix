# Minimus-only: OpenSSH and sops-based authorized_keys (oracle key)
# After first deploy, add root@minimus to .sops.yaml oracle-ssh rule and run: sops updatekeys modules/secrets/oracle-ssh.yaml
# Bootstrap step 1: leave keyFiles commented so first deploy doesn't need sops; uncomment after sops updatekeys.
{
  config,
  ...
}: {
  services.openssh.enable = true;

  # Uncomment after bootstrap (add root@minimus to .sops.yaml + sops updatekeys)
  # users.users.root.openssh.authorizedKeys.keyFiles = [
  #   config.sops.secrets.oracle_ssh_public.path
  # ];
  # users.users.joshammer.openssh.authorizedKeys.keyFiles = [
  #   config.sops.secrets.oracle_ssh_public.path
  # ];
}
