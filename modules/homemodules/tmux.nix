{
  config,
  pkgs,
  ...
}: {
  programs.tmux = let
    # Define Stylix colors as variables for readability
    # These are common base16 mappings; you can adjust them as you like.
    black = "#${config.stylix.base16Scheme.base00}";
    bg_highlight = "#${config.stylix.base16Scheme.base02}";
    blue = "#${config.stylix.base16Scheme.base0D}";
    cyan = "#${config.stylix.base16Scheme.base0C}";
    fg = "#${config.stylix.base16Scheme.base05}";
    magenta = "#${config.stylix.base16Scheme.base0E}";
    yellow = "#${config.stylix.base16Scheme.base0A}";
  in {
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

      # Use a vibrant color for the hostname
      set -g status-right "#[fg=${magenta},nobold,nounderscore,noitalics]#[fg=${black},bg=${magenta}] #h "
      bind v split-window -h -c '#{pane_current_path}'
      bind s split-window -v -c '#{pane_current_path}'
      bind c new-window -c '#{pane_current_path}'

      # Undercurl
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

      # tmux-resurrect configuration
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'

      # tmux-continuum configuration
      set -g @continuum-save-interval '5'
      set -g @continuum-restore 'on'

      # tmux-yank configuration (optional customizations)
      set -g @yank_selection_mouse 'clipboard'
      set -g @yank_action 'copy-pipe'

      # tmux-open configuration (optional customizations)
      set -g @open-S 'https://www.google.com/search?q='

      # --- THEMED COLORS START HERE ---
      set -g mode-style "fg=${blue},bg=${bg_highlight}"

      set -g message-style "fg=${blue},bg=${bg_highlight}"
      set -g message-command-style "fg=${blue},bg=${bg_highlight}"

      set -g pane-border-style "fg=${bg_highlight}"
      set -g pane-active-border-style "fg=${blue}"

      set -g status "on"
      set -g status-justify "left"

      set -g status-style "fg=${blue},bg=${black}"

      set -g status-left-length "100"
      set -g status-right-length "100"

      set -g status-left-style NONE
      set -g status-right-style NONE

      set -g status-left "#[fg=${black},bg=${blue},bold] #S #[fg=${blue},bg=${black},nobold,nounderscore,noitalics]"
      set -g status-right "#[fg=${blue},bg=${black},nobold,nounderscore,noitalics]#[fg=${black},bg=${blue},bold] #h "

      setw -g window-status-activity-style "underscore,fg=${fg},bg=${black}"
      setw -g window-status-separator ""
      setw -g window-status-style "NONE,fg=${fg},bg=${black}"
      setw -g window-status-format "#[fg=${black},bg=${black},nobold,nounderscore,noitalics]#[default] #I / #W #F #[fg=${black},bg=${black},nobold,nounderscore,noitalics]"
      setw -g window-status-current-format "#[fg=${black},bg=${bg_highlight},nobold,nounderscore,noitalics]#[fg=${blue},bg=${bg_highlight},bold] #I / #W #F #[fg=${bg_highlight},bg=${black},nobold,nounderscore,noitalics]"

      # tmux-plugins/tmux-prefix-highlight support
      set -g @prefix_highlight_output_prefix "#[fg=${yellow}]#[bg=${black}]#[fg=${black}]#[bg=${yellow}]"
      set -g @prefix_highlight_output_suffix ""
    '';
  };
}
