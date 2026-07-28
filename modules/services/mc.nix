# Minecraft server (malleum.us:25565) — the server itself lives in its own repo,
# github:malleum/mc, and is pulled in as the `mc` flake input. That repo holds
# the module, the bundled assets (height datapack, MythicMobs spawns) and the
# Waverider origin plugin source; see its CLAUDE.md for operational notes.
#
# Only host-specific values belong here. Everything else is an option on
# services.malleum-minecraft, documented in the mc repo's nix/module.nix.
{inputs, ...}: {
  unify.modules.mc.nixos = {hostConfig, ...}: {
    imports = [inputs.mc.nixosModules.minecraft];

    services.malleum-minecraft = {
      enable = true;

      # Whitelisted players and operators (level 4). Add names here, rebuild.
      whitelist = ["malleum" "opcornpay" "jaderabbit__" "sintfoap" "marvin1984"];
      admins = ["malleum"];

      # Identifies us to the Paper/Modrinth/Mojang APIs, as they ask.
      contactEmail = hostConfig.user.email;
      groupMembers = [hostConfig.user.username];
    };
  };
}
