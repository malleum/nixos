{
  unify.modules.gui.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      cursor-cli
      antigravity-cli
      claude-code
    ];
  };
}
