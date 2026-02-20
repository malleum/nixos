{
  unify.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      cursor-cli
      gemini-cli
      claude-code
    ];
  };
}
