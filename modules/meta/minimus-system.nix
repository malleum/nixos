# Build minimus with system = "aarch64-linux" so nixpkgs and binfmt match the ARM host.
# Unify's nixosSystem doesn't pass system, so evaluation uses the wrong platform when building remotely.
{
  config,
  inputs,
  lib,
  ...
}: let
  unify-lib = config._module.args.unify-lib or (throw "minimus-system: unify-lib not in _module.args");
  hostConfig = config.unify.hosts.nixos.minimus;

  nixosModules =
    (unify-lib.collectNixosModules hostConfig.modules)
    ++ [config.unify.nixos]
    ++ hostConfig.nixos.imports;

  homeModules = [
    config.unify.home
    hostConfig.home
  ];

  users =
    lib.mapAttrs (
      _: v: {
        imports = (unify-lib.collectHomeModules v.modules) ++ v.home.imports ++ homeModules;
      }
    )
    hostConfig.users;

  specialArgs = {inherit hostConfig;} // hostConfig.args;
in {
  flake.nixosConfigurations.minimus = lib.mkForce (
    inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      inherit specialArgs;
      modules =
        nixosModules
        ++ [
          inputs.home-manager.nixosModules.default
          {
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users = users;
          }
        ];
    }
  );
}
