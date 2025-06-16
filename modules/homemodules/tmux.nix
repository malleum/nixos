{pkgs, ...}: {
  programs.tmux = {
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
    extraConfig = ''
      set -g mouse on
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      set -g status-right "#[fg=colour133,nobold,nounderscore,noitalics]#[fg=colour0,bg=colour133] #h "
      bind v split-window -h -c '#{pane_current_path}'
      bind s split-window -v -c '#{pane_current_path}'
      bind c new-window -c '#{pane_current_path}'

      # Undercurl
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

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

      # tokyonight-night
      set -g mode-style "fg=#7aa2f7,bg=#3b4261"

      set -g message-style "fg=#7aa2f7,bg=#3b4261"
      set -g message-command-style "fg=#7aa2f7,bg=#3b4261"

      set -g pane-border-style "fg=#3b4261"
      set -g pane-active-border-style "fg=#7aa2f7"

      set -g status "on"
      set -g status-justify "left"

      set -g status-style "fg=#7aa2f7,bg=#16161e"

      set -g status-left-length "100"
      set -g status-right-length "100"

      set -g status-left-style NONE
      set -g status-right-style NONE

      set -g status-left "#[fg=#15161e,bg=#7aa2f7,bold] #S #[fg=#7aa2f7,bg=#16161e,nobold,nounderscore,noitalics]"
      set -g status-right "#[fg=#7aa2f7,bg=#16161e,nobold,nounderscore,noitalics]#[fg=#15161e,bg=#7aa2f7,bold] #h "

      setw -g window-status-activity-style "underscore,fg=#a9b1d6,bg=#16161e"
      setw -g window-status-separator ""
      setw -g window-status-style "NONE,fg=#a9b1d6,bg=#16161e"
      setw -g window-status-format "#[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]#[default] #I / #W #F #[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]"
      setw -g window-status-current-format "#[fg=#16161e,bg=#3b4261,nobold,nounderscore,noitalics]#[fg=#7aa2f7,bg=#3b4261,bold] #I / #W #F #[fg=#3b4261,bg=#16161e,nobold,nounderscore,noitalics]"

      # tmux-plugins/tmux-prefix-highlight support
      set -g @prefix_highlight_output_prefix "#[fg=#e0af68]#[bg=#16161e]#[fg=#16161e]#[bg=#e0af68]"
      set -g @prefix_highlight_output_suffix ""
    '';
  };
}
