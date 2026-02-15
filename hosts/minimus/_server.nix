# Minimus-only: OpenSSH and authorized_keys (oracle public key as literal to avoid /run at build time)
let
  oraclePublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+i3+8ZbQPDjp4Te8k7A11JLxMPMCiciUTtHDLBzLlvNK/F+2+UIviqCePxAkH/TAjjoU55T8ycEPDZr3li5id0T5qnAlAFT5AKtheyg76AHq/7rh+SQISRSdKNiLSblabd8iA62odFvU+7/KfFPj9fdnX5495+f3NkH8a5ZsXYhFxtU7rpEgiYEAWT3/GFb31+MxKTtP8zsCrtybCOJY2uNp6U6PGWcVsgOiS2N8Ew0a3Fb7UCRhdipOV34Nl92EaswBbOt2jjjukkjwFuhlw6gaCRxJM5UsynAu0YDISrW8yI8apI2oT9TCzLtO4IiL9iuGn5AI4wYjrrYdZLbNz ssh-key-2026-02-14";
in {
  # Avoid "Too many open files" during nix build on small VMs
  systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 65536;

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

  users.users.root.openssh.authorizedKeys.keys = [oraclePublicKey];
  users.users.joshammer.openssh.authorizedKeys.keys = [oraclePublicKey];
}
