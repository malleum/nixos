{
  unify.nixos = {config, ...}: let
    inherit (config.user) name username;
  in {
    users.users.${username} = {
      description = name;
      isNormalUser = true;
      extraGroups = ["adbusers" "video" "wheel"];
    };
  };
}
