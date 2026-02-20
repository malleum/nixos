{inputs, ...}: {
  unify.modules.gui.home = {pkgs, ...}: {
    home = {
      packages = with pkgs; [
        inputs.iamb.packages.${pkgs.stdenv.hostPlatform.system}.default
        iamb
        element-desktop
        signal-desktop
      ];
      file.".config/iamb/config.toml".source = (pkgs.formats.toml {}).generate "iamb-config" {
        profiles.user.user_id = "@malleum:ws42.top";
        layout.style = "restore";
        dirs = {
          downloads = "/tmp/iamb/";
        };
        settings = {
          message_user_color = true;
          timestamp_command = ["duod" "-u"];
          notifications = {
            enabled = true;
            via = "desktop";
          };
          username_display = "localpart";
          user_gutter_width = 16;
          image_preview = {};
          sort = {
            chats = ["unread" "recent"];
            dms = ["unread" "recent"];
            rooms = ["name"];
            spaces = ["name"];
          };
          users = {
            "@malleum:ws42.top".color = "blue";
            "@sintfoap:ws42.top".color = "red";
            "@tczcatlipoca:ws42.top".color = "yellow";
            "@rach:ws42.top".color = "light-yellow";
            "@marvin__1984:ws42.top".color = "green";
            "@emgrace:ws42.top".color = "light-green";
            "@l.8712:ws42.top".color = "magenta";
            "@crazy_happiness:ws42.top".color = "light-magenta";
            "@tarkus:ws42.top".color = "cyan";
            "@izzo:ws42.top".color = "light-cyan";
          };
        };

        macros = {
          normal = {
            "-" = ":chats<Enter>";
            "g-" = ":rooms<Enter>";
            "g_" = ":spaces<Enter>";
            "_" = ":dms<Enter>";

            "s" = ":join !ravyWNnYXUFelEmVNT:ws42.top<Enter>";
            "gl" = ":join !PvBreVmjlNxZpmIBIb:ws42.top<Enter>";
            "gm" = ":join !sxCRGFkKHoGqSXjIKL:ws42.top<Enter>";

            "g<Enter>" = ":reply<Enter>";
            "ge" = ":edit<Enter>";
            "gr" = ":react ";
            "gu" = ":unreact<Enter>";
            "gx" = ":open<Enter>";
            "gX" = ":download<Enter>";
            "gy" = "\"+y";
            "gp" = "\"+p";
            "gP" = "\"+P";
            "<C-C>" = ":cancel!<Enter>";

            "=1" = ":react 100<Enter>";
            "=a" = ":react saluting_face<Enter>";
            "=b" = ":react man_facepalming<Enter>";
            "=c" = ":react purple_circle<Enter>";
            "=d" = ":react thumbsdown<Enter>";
            "=e" = ":react eyes<Enter>";
            "=f" = ":react fire<Enter>";
            "=g" = ":react rainbow_flag<Enter>";
            "=h" = ":react heart<Enter>";
            "=i" = ":react point_up_2<Enter>";
            "=j" = ":react joy<Enter>";
            "=k" = ":react ok<Enter>";
            "=l" = ":react skull<Enter>";
            "=m" = ":react melting_face<Enter>";
            "=n" = ":react nerd_face<Enter>";
            "=o" = ":react ok_hand<Enter>";
            "=p" = ":react pensive<Enter>";
            "=r" = ":react woman_shrugging<Enter>";
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
