{config, ...}: {
  # Avoid "Too many open files" during nix build on small VMs
  systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 65536;

  users.users.root.openssh.authorizedKeys.keyFiles = [config.sops.secrets.oracle_ssh_public.path];
  users.users.joshammer.openssh.authorizedKeys.keyFiles = [config.sops.secrets.oracle_ssh_public.path];
}
