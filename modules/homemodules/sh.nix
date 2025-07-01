{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh"; # Optional: Keeps Zsh configs in ~/.config/zsh
    enableCompletion = true; # Enable Zsh's powerful completion system

    initContent = ''
      # Vi key bindings
      bindkey -v

      ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin


      function stag {
        export STAGING_BRANCH="$(git branch --show-current)"
      }

      function prod {
        export VS_RUN_PROD=1
      }

      if [[ -f "$HOME/documents/gh/k/abbr.zsh" ]]; then
          source "$HOME/documents/gh/k/abbr.zsh"
      fi

      # --- fzf integration ---
      # Ensure fzf's key bindings and completion are sourced.
      # Home Manager's programs.fzf often handles this if enableZshIntegration is true,
      # but explicit sourcing here is robust if you need custom options.
      if [ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]; then
        source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      fi
      if [ -f "${pkgs.fzf}/share/fzf/completion.zsh" ]; then
        source "${pkgs.fzf}/share/fzf/completion.zsh"
      fi

      export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --ansi"
      export FZF_COMPLETION_OPTS="--border --cycle --ansi"

      # --- Zsh Completion Fuzzy Matching (The core of Fish-like fuzzy tab) ---
      # This is crucial for single-Tab fuzzy finding before fzf-tab even pops up.
      # 'm:{a-zA-Z}={A-Za-z}' enables case-insensitive matching.
      # 'r:|[._-]=*' treats '.', '_', and '-' as wildcard characters for matching.
      # 'r:|=*' enables general fuzzy matching (allowing omitted characters).
      # 'l:|=* r:|=*' ensures fuzzy matching at both ends.
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # --- fzf-tab specific configuration ---
      # Consolidate all fzf-tab specific zstyle settings here.
      # Show descriptions of completions
      zstyle ':completion:*:descriptions' format '[%d]'
      # Show a preview for files/directories (consolidated from duplicates)
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'ls -F {}'
      # For 'cd' command, show a tree preview (consolidated from duplicates)
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --tree --level=2 --color=always {}'

      # Make the completion menu look nice (consolidated from duplicates)
      zstyle ':fzf-tab:*' fzf-preview-label 'Preview'
      zstyle ':fzf-tab:*' fzf-preview-window 'right:50%:hidden'

      precmd() {
        if [ "$?" -ne 0 ]; then
          notify-send "Command Failed!" "$(_last_command)"
        fi
      }
      function _last_command() { history -E 1 | head -n 1 | sed 's/^ *[0-9]* *//'; }
    '';

    shellAliases = {
      cat = "bat";
      la = "ls -lah";
      ls = "eza --icons --color";
      nixvim = "${config.home.homeDirectory}/.config/nixvim/result/bin/nvim";
      rm = "echo Use 'rip' instead of rm";
      rpy = "rg --iglob='*.py'";
    };

    # 9. Zsh Plugins (most efficient way in Home Manager)
    plugins = [
      {
        name = "zsh-autosuggestions"; # Fish-like history suggestions
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          # Check https://github.com/zsh-users/zsh-autosuggestions/releases for latest stable
          rev = "v0.7.1";
          sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo=";
        };
      }
      {
        name = "zsh-syntax-highlighting"; # Fish-like command highlighting
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          # Check https://github.com/zsh-users/zsh-syntax-highlighting/releases for latest stable
          rev = "0.8.0";
          sha256 = "sha256-iJdWopZwHpSyYl5/FQXEW7gl/SrKaYDEtTH9cGP7iPo=";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.2.0";
          sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
        };
      }
    ];
  };

  home.sessionVariables = {
    # This ensures 'man' uses 'grc' for colored output.
    MANPAGER = "sh -c 'col -bx | ${pkgs.grc}/bin/grc --colour -s | ${pkgs.less}/bin/less -R'";
  };

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

        alias cat "bat";
        alias la "ls -lah";
        alias ls "eza --icons --color";
        alias nixvim "~/.config/nixvim/result/bin/nvim";
        alias rm "echo Use 'rip' instead of rm";

        abbr -a stag "STAGING_BRANCH=(git branch --show-current)"
        abbr -a prod 'VS_RUN_PROD=1'
        abbr -a rpy rg --iglob='\'*.py'\'

        if test -f ~/documents/gh/k/abbr.fish
            source ~/documents/gh/k/abbr.fish
        end
      '';
    };
    zoxide.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      settings = {
        add_newline = true;
        format = lib.concatStrings [
          "$directory"
          "$git_branch"
          "$git_commit"
          "$git_state"
          "$git_metrics"
          "$git_status"
          "$line_break"
          "$character"
        ];
        right_format = lib.concatStrings [
          "$cmd_duration"
          "$nix_shell"
          "$direnv"
          "$docker_context"
          "$c"
          "$cmake"
          "$dart"
          "$deno"
          "$dotnet"
          "$golang"
          "$java"
          "$julia"
          "$kotlin"
          "$gradle"
          "$lua"
          "$nodejs"
          "$python"
          "$rust"
          "$typst"
          "$zig"
          "$line_break"
        ];
        scan_timeout = 10;
        character = {
          error_symbol = "[✗](bold red)";
        };
        directory = {
          truncation_length = 13;
          truncate_to_repo = false;
        };
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
  home.packages = with pkgs; [
    fishPlugins.autopair
    fishPlugins.colored-man-pages
    fishPlugins.done
    fishPlugins.grc
    fishPlugins.puffer

    eza
    fzf
    grc
  ];
}
