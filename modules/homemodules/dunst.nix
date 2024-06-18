{pkgs, ...}: {
  services.dunst = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome3.adwaita-icon-theme;
      size = "16x16";
    };
    settings = {
      global = {
        monitor = 0;
        geometry = "600x50-5+25";
        shrink = "yes";
        padding = 16;
        horizontal_padding = 16;
        line_height = 4;
        format = "<b>%s</b>\\n%b";
        corner_radius = 20;
      };
      shortcuts = {
        close_all = "ctrl+shift+space";
      };
    };
  };
}
