{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];

  options.home.enable = lib.mkEnableOption "enables home modules";

  config = lib.mkIf config.base.user.enable {
    programs = {
      zsh.enable = true;
      fish.enable = true;
      nh = {
        enable = true;
        clean.enable = true;
        flake = "/home/joshammer/.config/nixos";
      };
    };
    users = {
      users.joshammer = {
        isNormalUser = true;
        description = "Josh Hammer";
        extraGroups = ["adbusers" "audio" "libvirtd" "networkmanager" "video" "wheel" "kvm"];
        shell = pkgs.fish;
      };
      defaultUserShell = pkgs.fish;
    };

    home-manager = lib.mkIf config.home.enable {
      backupFileExtension = "backup";
      useGlobalPkgs = true;
      useUserPackages = true;
      users.joshammer = ../home.nix;
    };
  };
}
