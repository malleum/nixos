{
  unify.home =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.tmux =
        let
          getColorOrDefault =
            baseKey: defaultHex:
            if config ? stylix && config.stylix ? base16Scheme && config.stylix.base16Scheme ? ${baseKey} then
              "#${config.stylix.base16Scheme.${baseKey}}"
            else
              "#${defaultHex}";
          bg = getColorOrDefault "base00" "12151a";
          fg = getColorOrDefault "base05" "c5cbd3";
          accent = getColorOrDefault "base0D" "5e9de5";
          accent_fg = getColorOrDefault "base00" "12151a";
          highlight = getColorOrDefault "base0C" "88c0d0";
          highlight_fg = getColorOrDefault "base00" "12151a";
          pane_border = getColorOrDefault "base02" "3a424d";
          pane_active_border = getColorOrDefault "base0D" "5e9de5";
        in
        {
          enable = true;
          shortcut = "Space";
          terminal = "tmux-256color";
          clock24 = true;
          keyMode = "vi";
          baseIndex = 1;
          plugins = with pkgs.tmuxPlugins; [
            sensible
            tilish
            tmux-fzf
            resurrect
            continuum
            copycat
            yank
            open
          ];
          # Use an indented string (two single-quotes) to allow for Nix's ${...} interpolation
          extraConfig = ''
            set -g mouse on
            set-option -ga terminal-overrides ",xterm-256color:Tc"

            bind v split-window -h -c '#{pane_current_path}'
            bind s split-window -v -c '#{pane_current_path}'
            bind c new-window -c '#{pane_current_path}'

            # Undercurl
            set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
            set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

            # Plugin configurations
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
            set -g @continuum-save-interval '5'
            set -g @continuum-restore 'on'
            set -g @yank_selection_mouse 'clipboard'
            set -g @yank_action 'copy-pipe'
            set -g @open-S 'https://www.google.com/search?q='

            # --- SIMPLIFIED THEME ---
            set -g mode-style "fg=${accent},bg=${pane_border}"
            set -g message-style "fg=${accent},bg=${pane_border}"
            set -g message-command-style "fg=${accent},bg=${pane_border}"

            set -g pane-border-style "fg=${pane_border}"
            set -g pane-active-border-style "fg=${pane_active_border}"

            set -g status "on"
            set -g status-justify "left"
            set -g status-style "fg=${accent},bg=${bg}"

            set -g status-left-length "100"
            set -g status-right-length "100"
            set -g status-left-style NONE
            set -g status-right-style NONE

            # Unified active elements with a single accent color
            set -g status-left "#[fg=${accent_fg},bg=${accent},bold] #S #[fg=${accent},bg=${bg},nobold,nounderscore,noitalics]"
            set -g status-right "#[fg=${accent},bg=${bg},nobold,nounderscore,noitalics]#[fg=${accent_fg},bg=${accent},bold] #h "

            setw -g window-status-activity-style "underscore,fg=${fg},bg=${bg}"
            setw -g window-status-separator ""
            setw -g window-status-style "NONE,fg=${fg},bg=${bg}"
            setw -g window-status-format "#[fg=${bg},bg=${bg},nobold,nounderscore,noitalics]#[default] #I / #W #F #[fg=${bg},bg=${bg},nobold,nounderscore,noitalics]"
            setw -g window-status-current-format "#[fg=${bg},bg=${accent},nobold,nounderscore,noitalics]#[fg=${accent_fg},bg=${accent},bold] #I / #W #F #[fg=${accent},bg=${bg},nobold,nounderscore,noitalics]"

            # Prefix highlight uses a secondary, non-clashing accent color
            set -g @prefix_highlight_output_prefix "#[fg=${highlight}]#[bg=${bg}]#[fg=${highlight_fg}]#[bg=${highlight}]"
            set -g @prefix_highlight_output_suffix ""
          '';
        };
    };
}
