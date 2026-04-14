{
  unify.nixos = {
    pkgs,
    hostConfig,
    ...
  }: {
    programs.fish.enable = true;
    environment = {
      shells = [pkgs.fish];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        TERMINAL = "foot";
        BROWSER = hostConfig.user.browser;
        BROWSER2 = hostConfig.user.browser2;
      };
    };

    users.defaultUserShell = pkgs.fish;
  };

  unify.home = {pkgs, ...}: {
    programs = {
      fish = {
        enable = true;
        shellInit = ''
          function fish_command_not_found
              echo skill issue: $argv[1]
          end

          set -g fish_greeting ""

          fish_vi_key_bindings
          set fish_cursor_insert block
          ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

          # Abbreviations: g:m/ -> github:malleum/ , g:llm/ -> github:libertyluthermoffitt/
          function _rationalise_slash
              set -l token (commandline -t)
              if string match -q "*g:m" -- $token
                  commandline -t (string replace -r "g:m\$" "github:malleum/" -- $token)
              else if string match -q "*g:llm" -- $token
                  commandline -t (string replace -r "g:llm\$" "github:libertyluthermoffitt/" -- $token)
              else
                  commandline -i /
              end
          end
          bind -M insert / _rationalise_slash

          if test -f ~/documents/gh/k/abbr.fish
              source ~/documents/gh/k/abbr.fish
          end
        '';
        functions = {
          # Override grc's man wrapper — it has no grc config for man so it
          # shows grc's own help. User functions take precedence over vendor
          # conf.d regardless of load order, unlike shellInit erasing.
          man = ''
            set -lx LESS_TERMCAP_mb (printf '\e[1;35m')
            set -lx LESS_TERMCAP_md (printf '\e[1;34m')
            set -lx LESS_TERMCAP_me (printf '\e[0m')
            set -lx LESS_TERMCAP_so (printf '\e[33m')
            set -lx LESS_TERMCAP_se (printf '\e[0m')
            set -lx LESS_TERMCAP_us (printf '\e[1;32m')
            set -lx LESS_TERMCAP_ue (printf '\e[0m')
            command man $argv
          '';
        };
      };
    };

    home.packages = with pkgs; [
      fishPlugins.autopair
      fishPlugins.colored-man-pages
      fishPlugins.done
      fishPlugins.grc
      fishPlugins.puffer
      fishPlugins.fzf-fish
    ];
  };
}
