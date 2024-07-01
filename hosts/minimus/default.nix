{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  networking.hostName = "minimus";
  base = {
    enable = true;
    user.enable = true;
  };
  users.users.joshammer.initialPassword = "john11:25";

  home.enable = true;

  omni.enable = false;

  packages = {
    enable = true;
    minimus.enable = true;
    programming.enable = true;
  };
}
