{
  flake.modules.nixos.base = {
    config,
    hostConfig,
    ...
  }: let
    inherit (hostConfig.user) name username;
  in {
    # The login password, as a yescrypt hash made with `mkpasswd`. To change
    # it, make a new hash and replace the value with `sops
    # modules/secrets/default.yaml`. neededForUsers decrypts it to
    # /run/secrets-for-users before accounts are set up, which is the only
    # point at which a password file can be read.
    sops.secrets.user_system_passwd_hash.neededForUsers = true;

    # The config is the only source of accounts and passwords: every switch
    # resets them to what is declared here, so `passwd` does not stick and
    # users or groups added by hand disappear. Root gets no password at all,
    # which is fine while wheel has passwordless sudo.
    #
    # If the secret cannot be decrypted the account is left with NO usable
    # password. After the first switch on a host, check before logging out:
    #   sudo getent shadow "$USER" | cut -d: -f2 | cut -c1-3    # want $y$
    users.mutableUsers = false;

    users.users.${username} = {
      description = name;
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user_system_passwd_hash.path;
      extraGroups = [
        "video"
        "wheel"
      ];
    };
  };
}
