# Minecraft server (malleum.us:25565). The server, its plugins and the Matrix
# bot live in github:malleum/mc (nix/module.nix has the whitelist and every
# other switch); this only turns it on for hosts tagged "mc" and hands it the
# bot's secrets, which stay here with the rest of the sops files.
#
# After pushing a change there: `nix flake update mc`, then switch.
{inputs, ...}: {
  flake.modules.nixos.mc = {
    imports = [inputs.mc.nixosModules.default];
    services.malleum-mc = {
      enable = true;
      secretsFile = ../secrets/mcbot.yaml;
    };
  };
}
