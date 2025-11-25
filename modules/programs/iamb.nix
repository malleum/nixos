{
  unify.modules.gui.home = {pkgs, ...}: {
    home = {
      packages = with pkgs; [iamb];
      file.".config/iamb/config.toml".source = (pkgs.formats.toml {}).generate "iamb-config" {
        profiles.user.user_id = "@malleum:malleum.us";
        layout.style = "restore";
        settings = {
          message_user_color = true;
          notifications.enabled = true;
          username_display = "localpart";
          image_preview = {
            protocol = {
              type = "sixel";
              font_size = [11 26];
            };
          };
          users = {
            "@malleum:malleum.us".color = "blue";
            "@tczcatlipoca:malleum.us".color = "yellow";
            "@sintfoap:malleum.us".color = "red";
          };
        };

        macros = {
          normal = {
            "gc" = ":chats<Enter>";
            "-" = ":chats<Enter>";
            "ga" = "<C-W>m";
            "s" = "<C-W>m";
            "<C-g>" = "<C-W>mG<C-W>m";
            "gr" = ":react ";
            "ge" = ":edit ";
          };
        };
      };
    };
  };
}
