{
  imports = [./hardware-configuration.nix ../../modules];
  networking.hostName = "magnus";
  gpu.enable = true;
}
