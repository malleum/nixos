{
  pkgs,
  config,
  ...
}: {
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
    ];
    extraConfig = ''
      set -g mouse on
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      bind v split-window -h -c '#{pane_current_path}'
      bind s split-window -v -c '#{pane_current_path}'
      bind c new-window -c '#{pane_current_path}'

      # Undercurl
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

      set -g mode-style "fg=#${config.stylix.base16Scheme.base04},bg=#${config.stylix.base16Scheme.base00}"

      set -g message-style "fg=#${config.stylix.base16Scheme.base04},bg=#${config.stylix.base16Scheme.base00}"
      set -g message-command-style "fg=#${config.stylix.base16Scheme.base04},bg=#${config.stylix.base16Scheme.base00}"

      set -g pane-border-style "fg=#${config.stylix.base16Scheme.base00}"
      set -g pane-active-border-style "fg=#${config.stylix.base16Scheme.base0C}"

      set -g status "on"
      set -g status-justify "left"

      set -g status-style "fg=#${config.stylix.base16Scheme.base07},bg=#${config.stylix.base16Scheme.base00}"

      set -g status-left-length "100"
      set -g status-right-length "100"

      set -g status-left-style NONE
      set -g status-right-style NONE

      set -g status-left "#[fg=#${config.stylix.base16Scheme.base00},bg=#${config.stylix.base16Scheme.base0D},bold] #S #[fg=#${config.stylix.base16Scheme.base0D},bg=#${config.stylix.base16Scheme.base00},nobold,nounderscore,noitalics]"
      set -g status-right "#[fg=#${config.stylix.base16Scheme.base0D},nobold,nounderscore,noitalics,bg=#${config.stylix.base16Scheme.base00}]#[fg=#${config.stylix.base16Scheme.base00},bg=#${config.stylix.base16Scheme.base0D}] #h "

      setw -g window-status-separator ""
      setw -g window-status-activity-style "underscore,fg=#${config.stylix.base16Scheme.base09},bg=#${config.stylix.base16Scheme.base05}"
      setw -g window-status-style "NONE,fg=#${config.stylix.base16Scheme.base09},bg=#${config.stylix.base16Scheme.base01}"
      setw -g window-status-format "#[fg=#${config.stylix.base16Scheme.base00},bg=#${config.stylix.base16Scheme.base01},nobold,nounderscore,noitalics]#[fg=#${config.stylix.base16Scheme.base0D},bg=#${config.stylix.base16Scheme.base01}] #I  #W #F #[fg=#${config.stylix.base16Scheme.base01},bg=#${config.stylix.base16Scheme.base00},nobold,nounderscore,noitalics]"
      setw -g window-status-current-format "#[fg=#${config.stylix.base16Scheme.base00},bg=#${config.stylix.base16Scheme.base02},nobold,nounderscore,noitalics]#[fg=#${config.stylix.base16Scheme.base06},bg=#${config.stylix.base16Scheme.base02},bold] #I  #W #F #[fg=#${config.stylix.base16Scheme.base02},bg=#${config.stylix.base16Scheme.base00},nobold,nounderscore,noitalics]"

      # tmux-plugins/tmux-prefix-highlight support
      set -g @prefix_highlight_output_prefix "#[fg=#${config.stylix.base16Scheme.base04}]#[bg=#${config.stylix.base16Scheme.base01}]#[fg=#${config.stylix.base16Scheme.base01}]#[bg=#e0af68]"
      set -g @prefix_highlight_output_suffix ""
    '';
  };
}
