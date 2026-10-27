{
  flake.modules.homeManager.base = {pkgs, ...}: let
    shellAliases = {
      la = "eza -lah";
      cat = "bat";
      choose = "choose -x";
      claude = "claude --dangerously-skip-permissions";
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
      zsh = {
        shellAliases = shellAliases;
        initContent = ''
          # ca <branch> completes python-code branch names. An empty word lists open
          # worktrees only, so Tab does not dump every branch. See modules/scripts/_ca.nix.
          _ca() {
            if (( CURRENT == 2 )) && [[ $words[CURRENT] != -* ]]; then
              local output line section=open
              local -a open rest branches
              if [[ -z $words[CURRENT] ]]; then
                output="$(command ca --complete --open 2>/dev/null)" || return
              else
                output="$(command ca --complete 2>/dev/null)" || return
              fi
              [[ -n $output ]] || return
              for line in "''${(@f)output}"; do
                if [[ $line == -- ]]; then
                  section=rest
                  continue
                fi
                [[ -n $line ]] || continue
                if [[ $section == open ]]; then
                  open+=("$line")
                else
                  rest+=("$line")
                fi
              done
              branches=("''${open[@]}" "''${rest[@]}")
              (( ''${#branches} )) && compadd -V ca-branches -a branches
            fi
          }
          compdef _ca ca
        '';
      };
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
