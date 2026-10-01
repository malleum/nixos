# Session-wide environment. Lived in both fish.nix and zsh.nix as duplicate
# definitions; it is shell-agnostic, so it belongs to neither.
{
  flake.modules.nixos.base = {hostConfig, ...}: {
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "foot";
      BROWSER = hostConfig.user.browser;
      BROWSER2 = hostConfig.user.browser2;
    };
  };
}
