{
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

    ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        clipboard-paste-protection = false;
        cursor-style = "block";
        cursor-style-blink = false;
        mouse-hide-while-typing = true;
        shell-integration-features = "no-cursor";
        window-decoration = false;
        confirm-close-surface = false;
      };
    };
  };
}
