# Turns `hosts.<name>` into `nixosConfigurations.<name>`.
#
# Feature files write to one of:
#   flake.modules.nixos.base / flake.modules.homeManager.base   every host
#   flake.modules.nixos.<tag> / flake.modules.homeManager.<tag> hosts listing <tag>
#
# Every module (NixOS and home-manager) gets `hostConfig` as a special arg:
# the host's name plus the flake-level `user` and `flakePath`.
{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (config.flake.modules) nixos homeManager;

  # A tag may only have a nixos or only a home side; a tag with neither is a
  # typo in a host file.
  pick = class: tag:
    if nixos ? ${tag} || homeManager ? ${tag}
    then class.${tag} or {}
    else throw "hosts: unknown tag `${tag}`";
in {
  imports = [inputs.flake-parts.flakeModules.modules];

  options.hosts = mkOption {
    default = {};
    type = types.attrsOf (types.submodule {
      options = {
        tags = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Opt-in features: names under flake.modules.{nixos,homeManager}.";
        };
        modules = mkOption {
          type = types.listOf types.deferredModule;
          default = [];
          description = "Host-only NixOS modules (hardware config, quirks).";
        };
      };
    });
  };

  config.flake.nixosConfigurations =
    lib.mapAttrs (
      name: host: let
        hostConfig = {
          inherit name;
          inherit (config) user flakePath;
        };
      in
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {inherit hostConfig;};
          modules =
            map (pick nixos) host.tags
            ++ [nixos.base]
            ++ host.modules
            ++ [
              inputs.home-manager.nixosModules.default
              {
                home-manager.extraSpecialArgs = {inherit hostConfig;};
                home-manager.users.${config.user.username}.imports =
                  map (pick homeManager) host.tags ++ [homeManager.base];
              }
            ];
        }
    )
    config.hosts;
}
