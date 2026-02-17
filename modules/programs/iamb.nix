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

            "=m" = ":react melting_face<Enter>";
            "=f" = ":react fire<Enter>";
            "=p" = ":react pensive<Enter>";
            "=j" = ":react joy<Enter>";
            "=u" = ":react thumbsup<Enter>";
            "=d" = ":react thumbsdown<Enter>";
            "=g" = ":react rainbow_flag<Enter>";
            "=w" = ":react watermelon<Enter>";
            "=t" = ":react thinking<Enter>";
            "=e" = ":react eyes<Enter>";
            "=n" = ":react nerd_face<Enter>";
            "=s" = ":react snowflake<Enter>";
            "=h" = ":react heart<Enter>";
            "=y" = ":react tada<Enter>";
            "=o" = ":react ok_hand<Enter>";
            "=k" = ":react ok<Enter>";
            "=1" = ":react 100<Enter>";
            "=c" = ":react purple_circle<Enter>";
            "=i" = ":react point_up_2";

            "\\m" = ":unreact melting_face<Enter>";
            "\\f" = ":unreact fire<Enter>";
            "\\p" = ":unreact pensive<Enter>";
            "\\j" = ":unreact joy<Enter>";
            "\\u" = ":unreact thumbsup<Enter>";
            "\\d" = ":unreact thumbsdown<Enter>";
            "\\g" = ":unreact rainbow_flag<Enter>";
            "\\w" = ":unreact watermelon<Enter>";
            "\\t" = ":unreact thinking<Enter>";
            "\\e" = ":unreact eyes<Enter>";
            "\\n" = ":unreact nerd_face<Enter>";
            "\\s" = ":unreact snowflake<Enter>";
            "\\h" = ":unreact heart<Enter>";
            "\\y" = ":unreact tada<Enter>";
            "\\o" = ":unreact ok_hand<Enter>";
            "\\k" = ":unreact ok<Enter>";
            "\\1" = ":unreact 100<Enter>";
            "\\c" = ":unreact purple_circle<Enter>";
            "\\i" = ":unreact point_up_2";
          };
        };
      };
    };
  };
}
