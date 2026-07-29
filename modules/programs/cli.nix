{
  unify.home = {pkgs, ...}: let
    shellAliases = {
      la = "eza -lah";
      cat = "bat";
      choose = "choose -x";
      claude = "claude --dangerously-skip-permissions";
      ca = "cursor-agent";
    };
  in {
    programs = {
      zoxide.enable = true;
      eza = {
        enable = true;
        icons = "auto";
      };
      direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
      };
      zsh.shellAliases = shellAliases;
    };

    home = {
      packages = with pkgs; [grc];

      sessionVariables = {
        MANPAGER = "sh -c 'col -bx | ${pkgs.grc}/bin/grc --colour -s | ${pkgs.less}/bin/less -R'";
      };
    };
  };
}
