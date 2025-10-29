{
  unify.modules.gui.home = {
    programs = {
      foot = {
        enable = true;
        settings = {
          cursor.style = "block";
          main.term = "xterm-256color";
          mouse.hide-when-typing = "yes";
          scrollback.lines = 1048576;
        };
      };

      kitty = {
        enable = true;
        extraConfig = ''
          enable_audio_bell no

          map ctrl+shift+w discard_event
        '';
      };
    };
  };
}
