{
  unify.home = {
    config,
    pkgs,
    ...
  }: {
    programs.tmux = let
      getColorOrDefault = baseKey: defaultHex:
        if config ? stylix && config.stylix ? base16Scheme && config.stylix.base16Scheme ? ${baseKey}
        then "#${config.stylix.base16Scheme.${baseKey}}"
        else "#${defaultHex}";
      bg = getColorOrDefault "base00" "12151a";
      fg = getColorOrDefault "base05" "c5cbd3";
      accent = getColorOrDefault "base0D" "5e9de5";
      accent_fg = getColorOrDefault "base00" "12151a";
      highlight = getColorOrDefault "base0C" "88c0d0";
      highlight_fg = getColorOrDefault "base00" "12151a";
      pane_border = getColorOrDefault "base02" "3a424d";
      pane_active_border = getColorOrDefault "base0D" "5e9de5";
    in {
      enable = true;
      shortcut = "Space";
      terminal = "tmux-256color";
      clock24 = true;
      keyMode = "vi";
      baseIndex = 1;
      # Plugins that read an @-option at load time are deliberately NOT here --
      # see the bottom of extraConfig. home-manager emits this list as run-shell
      # lines *before* extraConfig, so anything configured by a `set -g @...`
      # would read the default instead of your value.
      plugins = with pkgs.tmuxPlugins; [
        sensible
        tilish
        yank
        open
      ];
      # Use an indented string (two single-quotes) to allow for Nix's ${...} interpolation
      extraConfig = ''
        set -g mouse on
        set-option -ga terminal-overrides ",xterm-256color:Tc"

        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi y send -X copy-selection-and-cancel

        # Mouse-drag select shouldn't kick out of copy-mode (that snaps scroll
        # back to bottom). Stay in copy-mode after copying.
        bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-no-clear "wl-copy"
        bind -T copy-mode MouseDragEnd1Pane send -X copy-pipe-no-clear "wl-copy"

        bind v split-window -h -c '#{pane_current_path}'
        bind s split-window -v -c '#{pane_current_path}'
        bind c new-window -c '#{pane_current_path}'

        # Undercurl
        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

        # Plugin configurations
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

        # ── Session persistence (must stay last) ─────────────────────
        #
        # continuum has no timer of its own: at load it appends
        # "#{continuum_status}" to whatever status-right currently holds, and
        # relies on tmux re-evaluating status-right every status-interval to
        # fire the save. Load order is therefore everything.
        #
        # home-manager emits programs.tmux.plugins as run-shell lines *above*
        # extraConfig, so with continuum listed there it read the default
        # status-right, appended its hook, and then the theme block above
        # overwrote status-right and threw the hook away. Autosave silently
        # never ran again -- the newest save on disk was three months stale
        # while @continuum-save-last-timestamp only ever showed server start
        # time. The @continuum-* options had the same problem: set after the
        # plugin had already read them.
        #
        # So: options first, then the theme's status-right, then resurrect,
        # then continuum dead last. Upstream says the same ("tmux-continuum
        # should be the last plugin in the list").
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-strategy-vim 'session'
        set -g @resurrect-strategy-nvim 'session'
        set -g @continuum-save-interval '5'
        set -g @continuum-restore 'on'

        # Same trap: tmux-thumbs binds get_tmux_option "@thumbs-key" at load,
        # so listed above it bound its default (prefix Space) and ignored this.
        # Plain `o`, not C-o: C-o is Claude Code's own key inside the pane.
        # It replaces tmux's builtin `select-pane -t :.+`, which super-h/j/k/l
        # already covers at the window-manager level.
        set -g @thumbs-key o
        set -g @thumbs-command 'echo -n {} | wl-copy'
        set -g @thumbs-position 'left'

        run-shell ${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs/tmux-thumbs.tmux

        # tmux-thumbs.tmux binds the key as `run-shell -b`, and on tmux 3.7b the
        # backgrounded form is a silent no-op: the wrapper never starts, so
        # prefix C-o did nothing at all. Verified by hand -- `run-shell -b
        # tmux-thumbs.sh` produced no window and no error (the wrapper ends in
        # `|| true`, so failures are swallowed), while the same script without
        # -b brought up the hint overlay and copied the pick. So rebind on top
        # of the plugin's own binding, foreground.
        bind-key -T prefix o run-shell ${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs/tmux-thumbs.sh

        run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
        run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
      '';
    };
  };
}
