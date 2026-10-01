{
  flake.modules.homeManager.base = {pkgs, ...}: let
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
      # Tokyonight night, matching mvim's colorscheme (same tokyonight.nvim
      # extras). mvim's fzf previews and MANPAGER pick it up from this config.
      # Vendored like mvim/colors/tokyonight.lua, so no host builds the whole
      # plugin for one file; see that file's header for how to refresh both.
      bat = {
        enable = true;
        config.theme = "tokyonight_night";
        themes.tokyonight_night.src = ./tokyonight_night.tmTheme;
      };
    };

    home = {
      packages = with pkgs; [grc];

      sessionVariables = {
        MANPAGER = "sh -c 'col -bx | ${pkgs.grc}/bin/grc --colour -s | ${pkgs.less}/bin/less -R'";
      };
    };
  };
}
