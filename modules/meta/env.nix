# Session-wide environment. Lived in both fish.nix and zsh.nix as duplicate
# definitions; it is shell-agnostic, so it belongs to neither.
{
  unify.nixos = {hostConfig, ...}: {
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "foot";
      BROWSER = hostConfig.user.browser;
      BROWSER2 = hostConfig.user.browser2;
    };
  };
}
