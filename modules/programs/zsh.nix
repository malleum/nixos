{
  unify.nixos = {
    pkgs,
    hostConfig,
    lib,
    ...
  }: {
    programs.zsh.enable = true;
    environment = {
      shells = [pkgs.zsh];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        TERMINAL = "foot";
        BROWSER = hostConfig.user.browser;
        BROWSER2 = hostConfig.user.browser2;
      };
    };

    users.defaultUserShell = lib.mkForce pkgs.zsh;
  };

  unify.home = {pkgs, config, ...}: {
    programs = {
      zsh = {
        enable = true;
        autosuggestion.enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        dotDir = "${config.xdg.configHome}/zsh";

        history = {
          size = 10000;
          path = "$HOME/.local/share/zsh/history";
        };

        initContent = ''
          # Vi mode
          bindkey -v
          export KEYTIMEOUT=1

          # Command not found
          command_not_found_handler() {
              echo "skill issue: $1"
              return 127
          }

          # any-nix-shell (without --info-right: its precmd sets RPROMPT directly,
          # wiping starship's right prompt; starship's $nix_shell module handles display)
          ${pkgs.any-nix-shell}/bin/any-nix-shell zsh | source /dev/stdin

          # Autopair (like fish's autopair plugin)
          source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh

          # grc colorizes command output (ping, df, etc.)
          source ${pkgs.grc}/etc/grc.zsh

          # Colored man pages via bat
          # MANROFFOPT -c forces groff to use backspace formatting instead of SGR
          # codes, so col -bx can strip them cleanly before bat highlights
          export MANPAGER="sh -c 'col -bx | bat -l man -p'"
          export MANROFFOPT="-c"

          # fzf keybindings: Ctrl+R history, Ctrl+T file search, Alt+C cd
          source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          source ${pkgs.fzf}/share/fzf/completion.zsh

          # Ctrl+P: fzf process search (Ctrl+P = prev-history in emacs mode but free in vi insert)
          function _fzf_process_widget {
            local pid
            pid=$(ps aux | fzf --header-lines=1 --prompt='Process> ' --preview='echo {}' | awk '{print $2}')
            if [[ -n $pid ]]; then
              LBUFFER+=$pid
            fi
            zle reset-prompt
          }
          zle -N _fzf_process_widget
          bindkey '^P' _fzf_process_widget

          # Vi cursor: block in both modes (matches fish's fish_cursor_insert block)
          # Call any previously-registered zle-line-init (e.g. starship's timing hook) first
          function zle-line-init {
            (( $+functions[starship_zle-line-init] )) && starship_zle-line-init
            echo -ne '\e[2 q'
          }
          function zle-keymap-select {
            echo -ne '\e[2 q'
          }
          zle -N zle-keymap-select
          zle -N zle-line-init

          # Notify when a command takes longer than 10s (like fish's done plugin)
          _cmd_start=0
          function _preexec_timer { _cmd_start=$EPOCHSECONDS }
          function _precmd_notify {
            if (( _cmd_start > 0 )); then
              local elapsed=$(( EPOCHSECONDS - _cmd_start ))
              if (( elapsed >= 10 )); then
                notify-send "Done" "Finished in ''${elapsed}s" 2>/dev/null
              fi
              _cmd_start=0
            fi
          }
          autoload -Uz add-zsh-hook
          add-zsh-hook preexec _preexec_timer
          add-zsh-hook precmd _precmd_notify

          # Puffer: ... → ../.. , .... → ../../.. etc.
          function _rationalise-dot {
            if [[ $LBUFFER = *.. ]]; then
              LBUFFER+=/..
            else
              LBUFFER+=.
            fi
          }
          zle -N _rationalise-dot
          bindkey . _rationalise-dot
          # Still allow . in completion context (e.g. .hidden files)
          bindkey -M isearch . self-insert

          # Alt+F: accept next word of autosuggestion (fish-like partial accept)
          bindkey '^[f' forward-word

          # Fish-like completion:
          # Tab 1: complete common prefix + show list
          # Tab 2+: cycle through options, each inserted on CLI
          # Enter: accept; Space: accept and continue typing
          setopt AUTO_LIST        # show list on first ambiguous Tab
          setopt AUTO_MENU        # enter menu mode on second Tab
          unsetopt MENU_COMPLETE  # don't auto-insert first match on Tab 1
          unsetopt LIST_AMBIGUOUS # show list even when a common prefix was inserted
          unsetopt AUTO_REMOVE_SLASH  # don't strip trailing / from dirs on space

          # Fuzzy + substring + case-insensitive matching
          zstyle ':completion:*' matcher-list \
            'm:{a-zA-Z}={A-Za-z}' \
            'r:|[._-]=* r:|=*' \
            'l:|=* r:|=*'

          # Menu select: highlighted item is inserted on CLI as you cycle
          zstyle ':completion:*' menu select
          # Fish-like flag descriptions: bold flag, dim separator, colored description
          # =(#b) pattern: group 1 = --flag (bold), group 2 = ' -- ' (dim), group 3 = description (italic cyan)
          zstyle ':completion:*' list-colors \
            "''${(s.:.)LS_COLORS}" \
            '=(#b)(--[^ =]*)( -- )(*)=1=2=3;36'
          # Group headers in dim parens (e.g. "(options)" above the flags list)
          zstyle ':completion:*:descriptions' format '%F{8}(%d)%f'
        '';

        shellAliases = {
          la = "eza -lah";
          cat = "bat";
          choose = "choose -x";
        };
      };
    };

    home.packages = with pkgs; [
      zsh-autopair
      grc
      fzf
    ];
  };
}
