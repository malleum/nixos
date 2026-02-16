{
  unify.modules.gui.home = {pkgs, ...}: {
    home = {
      packages = with pkgs; [iamb element-desktop signal-desktop];
      file.".config/iamb/config.toml".source = (pkgs.formats.toml {}).generate "iamb-config" {
        profiles.user.user_id = "@malleum:ws42.top";
        layout.style = "restore";
        settings = {
          message_user_color = true;
          notifications.enabled = true;
          username_display = "localpart";
          image_preview = {};
          users = {
            "@malleum:ws42.top".color = "blue";
            "@tczcatlipoca:ws42.top".color = "yellow";
            "@sintfoap:ws42.top".color = "red";
          };
        };

        macros = {
          normal = {
            "-" = ":chats<Enter>";
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
