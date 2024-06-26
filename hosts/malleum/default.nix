{
  imports = [./hardware-configuration.nix ../../modules];
  networking.hostName = "malleum";
  battery.enable = true;
}
