{
  unify.modules.ai.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      cursor-cli
      antigravity-cli
      claude-code
      code-cursor-fhs
    ];
  };
}
