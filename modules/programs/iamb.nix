{
  unify.modules.cht.home = {
    lib,
    pkgs,
    ...
  }: let
    jiamb = pkgs.iamb;

    # Launched at login, not supervised -- see the helper for why these are
    # Restart=no with X-SwitchMethod=keep-old.
    mkSessionUnit = import ./jay/_session-unit.nix {inherit lib;};

    # Jay is not GNOME; Electron will not auto-pick libsecret.
    withGnomeLibsecret = pkg: bin:
      pkgs.symlinkJoin {
        name = "${pkg.pname or bin}-libsecret";
        paths = [pkg];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/${bin} --add-flags "--password-store=gnome-libsecret"
        '';
      };

    signal = withGnomeLibsecret pkgs.signal-desktop "signal-desktop";
    element = withGnomeLibsecret (pkgs.element-desktop.override {
      element-web = pkgs.element-web.override {
        conf = {
          default_server_config."m.homeserver" = {
            base_url = "https://ws42.top";
            server_name = "ws42.top";
          };
          element_call = {
            url = "https://call.element.io";
            use_exclusively = true;
          };
          features = {
            feature_group_calls = true;
            feature_video_rooms = true;
            feature_element_call_video_rooms = true;
          };
        };
      };
    }) "element-desktop";
  in {
    systemd.user.services = {
      signal = mkSessionUnit {
        description = "Signal";
        exec = "${signal}/bin/signal-desktop";
        restart = false;
        guard = "${pkgs.bash}/bin/bash -c '! ${pkgs.procps}/bin/pgrep -x -u \"$USER\" signal-desktop >/dev/null'";
      };

      iamb = mkSessionUnit {
        description = "iamb matrix client";
        # iamb panics (rust exit 101) if the initial sync has no network,
        # and jay-session.target starts well before NetworkManager has
        # actually got a connection up -- so wait for it first. nm-online
        # returns immediately once connected; -t caps the wait so a
        # genuinely offline boot still opens iamb (to its own error) rather
        # than hanging the session forever.
        exec = "${pkgs.bash}/bin/bash -c '${pkgs.networkmanager}/bin/nm-online -q -t 30; exec ${pkgs.foot}/bin/foot --app-id=iamb --title=iamb ${jiamb}/bin/iamb'";
        restart = false;
        # Skip the start if an iamb is already up -- systemd-launched or
        # spawned by hand from a terminal. See _session-unit.nix.
        guard = "${pkgs.bash}/bin/bash -c '! ${pkgs.procps}/bin/pgrep -x -u \"$USER\" iamb >/dev/null'";
      };
    };

    home = {
      sessionVariables = {
        IAMB_DICT_EN_AFF = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.aff";
        IAMB_DICT_EN_DIC = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.dic";
        IAMB_DICT_NB_AFF = "${pkgs.hunspellDicts.nb_NO}/share/hunspell/nb_NO.aff";
        IAMB_DICT_NB_DIC = "${pkgs.hunspellDicts.nb_NO}/share/hunspell/nb_NO.dic";
      };
      packages = [
        jiamb
        element
        signal
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
            "@mr_vermillion:ws42.top".color = "dark-gray";
            "@generic_eric:ws42.top".color = "gray";
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
            "<C-C>" = ":cancel!<Enter>";

            # Clipboard paste, matching the nvim leader maps.
            "<Space>p" = "\"+p";
            "<Space>P" = "\"+P";

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

          # Same leader maps as nvim: yank to the system clipboard, delete into
          # the black hole.
          "normal|visual" = {
            "<Space>y" = "\"+y";
            "<Space>Y" = "\"+y$";
            "<Space>d" = "\"_d";
            "<Space>D" = "\"_D";
          };

          # Paste over a selection without losing what's in the register.
          visual = {
            "<Space>p" = "\"_dP";
          };
        };
      };
    };
  };
}
