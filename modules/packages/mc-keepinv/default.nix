# The KeepInvList plugin as a flake package, so `nix build .#mc-keepinv` works
# and modules/services/mc.nix has exactly one definition to consume.
# _plugin.nix holds the derivation (underscore: import-tree skips it).
{
  perSystem = {pkgs, ...}: {
    packages.mc-keepinv = pkgs.callPackage ./_plugin.nix {};
  };
}
