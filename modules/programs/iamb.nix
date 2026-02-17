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
            "g-" = ":rooms<Enter>";
            "g_" = ":spaces<Enter>";
            "_" = ":dms<Enter>";
            "gg" = ":reply<Enter>";
            "ge" = ":edit<Enter>";
            "gr" = ":react ";
            "gn" = ":unreact ";
            "gu" = ":unreact<Enter>";
            "gy" = "\"+yy";
            "gp" = "\"+p";
            "gP" = "\"+P";
            "<C-C>" = ":cancel!<Enter>";

            "=1" = ":react 100<Enter>";
            "=c" = ":react purple_circle<Enter>";
            "=d" = ":react thumbsdown<Enter>";
            "=e" = ":react eyes<Enter>";
            "=f" = ":react fire<Enter>";
            "=g" = ":react rainbow_flag<Enter>";
            "=h" = ":react heart<Enter>";
            "=i" = ":react point_up_2";
            "=j" = ":react joy<Enter>";
            "=k" = ":react ok<Enter>";
            "=l" = ":react skull";
            "=m" = ":react melting_face<Enter>";
            "=n" = ":react nerd_face<Enter>";
            "=o" = ":react ok_hand<Enter>";
            "=p" = ":react pensive<Enter>";
            "=s" = ":react snowflake<Enter>";
            "=t" = ":react thinking<Enter>";
            "=u" = ":react thumbsup<Enter>";
            "=w" = ":react watermelon<Enter>";
            "=y" = ":react tada<Enter>";
          };
        };
      };
    };
  };
}
