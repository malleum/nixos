{
  programs = {
    kitty = {
      enable = true;
      settings = {
        enable_audio_bell = false;
        confirm_os_window_close = "0";
      };
      extraConfig = ''
        map ctrl+c copy_or_interrupt
        map kitty_mod+w no_op
        map shift+cmd+d no_op
        map ctrl+d no_op
      '';
    };

    foot = {
      enable = true;
      settings = {
        main.term = "xterm-256color";
        mouse.hide-when-typing = "yes";
      };
    };

    alacritty.enable = true;
  };
}
