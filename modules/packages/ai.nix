{
  unify.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      cursor-cli
      code-cursor-fhs
      gemini-cli
      claude-code
      aider-chat-full
    ];
  };
}
