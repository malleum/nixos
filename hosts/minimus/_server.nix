# Minimus-only: OpenSSH and sops-based authorized_keys (oracle key)
# After first deploy, add root@minimus to .sops.yaml oracle-ssh rule and run: sops updatekeys modules/secrets/oracle-ssh.yaml
# Bootstrap step 1: leave keyFiles commented so first deploy doesn't need sops; uncomment after sops updatekeys.
{config, ...}: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Default password for initial login (change after first login): minimus-setup
  users.users.root.hashedPassword = "$6$cvDv8MHETjaPUI8m$OcEsvrrFl3sQ7gy43HAVfht.Kw4H.YvPTUSGZFsa/LJopZtU1wrsoCJKxobFBh1qeyUdkcS4MP2OuyPrLD8OB.";
  users.users.joshammer.hashedPassword = "$6$cvDv8MHETjaPUI8m$OcEsvrrFl3sQ7gy43HAVfht.Kw4H.YvPTUSGZFsa/LJopZtU1wrsoCJKxobFBh1qeyUdkcS4MP2OuyPrLD8OB.";

  # Uncomment after bootstrap (add root@minimus to .sops.yaml + sops updatekeys)
  # users.users.root.openssh.authorizedKeys.keyFiles = [
  #   config.sops.secrets.oracle_ssh_public.path
  # ];
  # users.users.joshammer.openssh.authorizedKeys.keyFiles = [
  #   config.sops.secrets.oracle_ssh_public.path
  # ];
}
