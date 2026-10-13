# cerbo (github:malleum/cerbo) -- ask a local model to do something in the
# shell: `cerbo change my sound output to the TV`. llama-swap serves Qwen3.5-9B
# on loopback, loading it on the first call and dropping it after two idle
# minutes so the VRAM goes back to games. `cerbo off` drops it at once.
#
# The server is magnus only: it is the one host with a GPU that runs a 9B
# model at speed. Every other host is a `cerbo-client`: the command runs there
# and acts on that machine, while a user service holds an ssh -L through
# minimus (the `magnus` block in programs/ssh.nix) so the model calls land on
# magnus. If magnus is off, cerbo says the model is unreachable and the tunnel
# keeps retrying every 30 s until it is back.
#
# Port 8091 is pipedream's on minimus too, but only on its loopback; the
# client end of the tunnel there takes 8092 instead.
{inputs, ...}: let
  # Where things live, so "the X repo" does not start with a search of $HOME.
  repoHints = ''
    - Repos: most are in ~/documents/gh/<name> (lowercase "documents"). The
      NixOS config is a repo at ~/.config/nixos.
  '';

  # The Minecraft server (services/mc.nix) runs on minimus. Each command was
  # checked against the live server: mc-console's -c drops the colour codes
  # that would otherwise fill the model's context, and the world is "42".
  # `sudo -n` is passwordless for wheel, and spelled out as the exception
  # because cerbo's built-in rules say never to use sudo. Only minimus gets
  # these: cerbo elsewhere is not meant to reach the server.
  mcLocal = ''
    - Minecraft server: Paper, systemd unit `minecraft`, data in /var/lib/minecraft
      (root-only), world "42". Its console is the one place sudo is allowed:
      `sudo -n mc-console -c "<command>"` runs one server command and prints
      plain output, e.g. `list` (who is online), `tps`, `say <message>`
      (broadcast to chat), `whitelist list`.
    - Minecraft chat, joins and leaves:
      `journalctl -u minecraft --since today --no-pager | grep -E '<[^>]+>|joined the game|left the game'`
    - Minecraft player stats: UUIDs by name in /var/lib/minecraft/usercache.json, then
      `sudo -n jq '.stats["minecraft:custom"]["minecraft:play_time"]' /var/lib/minecraft/42/players/stats/<uuid>.json`
      play_time is in ticks (20 per second: hours = ticks / 72000); other keys under
      "minecraft:custom" include "minecraft:deaths" and "minecraft:jump".
  '';

  # jay, PipeWire, nmcli, git and nix already have built-in recipes in cerbo,
  # chosen by what is installed; these are only what it cannot know.
  desktopHints = repoHints;

  serverHints =
    repoHints
    + ''
      - This is minimus, a headless aarch64 server (Oracle Cloud): no desktop, no
        audio. Everything it does is a system service; start from
        `systemctl list-units --type=service --state=running`. Websites go through
        nginx (`systemctl status nginx`).
    ''
    + mcLocal;
in {
  flake.modules.nixos.cerbo = {
    imports = [inputs.cerbo.nixosModules.default];

    services.cerbo = {
      enable = true;
      # The 7700 XT. Vulkan also sees the Raphael iGPU, and render-node order
      # is not stable on magnus (see hardware/amd.nix).
      vulkanDevice = "1002:747e";
      # Short: amdgpu will page an idle model out to RAM when a game wants the
      # VRAM, but games size their textures from the free VRAM they see at
      # launch, and a reload from page cache is only ~3 s.
      ttl = 120;
    };
  };

  flake.modules.homeManager.cerbo = {
    imports = [inputs.cerbo.homeManagerModules.default];

    programs.cerbo = {
      enable = true;
      hints =
        desktopHints
        + ''
          - Monitor audio: HDMI/DisplayPort sinks belong to the GPU card
            (alsa_output.pci-0000_03_00.1.*). Each card port is one display connector;
            `pactl -f json list cards | jq '.[] | .ports'` shows which are "available".
            Only an enabled display has an available port, so a disabled display has to
            be enabled before its audio can be selected. Port names (e.g. "25E3A") come
            from the monitor's audio EDID and do not match jay's product names.
        '';
    };
  };

  flake.modules.homeManager.cerbo-client = {hostConfig, ...}: let
    # minimus is the jump host itself: go straight to its loopback end of
    # magnus's reverse tunnel instead of jumping through itself.
    onMinimus = hostConfig.name == "minimus";
  in {
    imports = [inputs.cerbo.homeManagerModules.default];

    programs.cerbo = {
      enable = true;
      tunnel = {
        host = "magnus";
        localPort =
          if onMinimus
          then 8092
          else 8091;
        sshArgs = inputs.nixpkgs.lib.optionals onMinimus ["-o" "ProxyJump=none"];
      };
      hints =
        if onMinimus
        then serverHints
        else desktopHints;
    };
  };
}
