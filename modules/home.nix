{pkgs, ...}: let
  username = "joshammer";
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";
in {
  imports = [./homemodules];
  stylix.targets = {
    tmux.enable = false;
    fish.enable = false;
  };

  home = {
    inherit username homeDirectory;
    enableNixpkgsReleaseCheck = false;
    stateVersion = "23.11";
  };

  xdg = {
    inherit configHome;
    enable = true;
  };

  programs = {
    hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 300;
          hide_cursor = true;
          no_fade_in = false;
        };
        background = [
          {
            path = "/home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg";
            blur_passes = 3;
            blur_size = 8;
          }
        ];
        input-field = [
          {
            size = "200, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(202, 211, 245)";
            inner_color = "rgb(91, 96, 120)";
            outer_color = "rgb(24, 25, 38)";
            outline_thickness = 5;
            placeholder_text = "'Password...'";
            shadow_passes = 2;
          }
        ];
      };
    };
    git = {
      enable = true;
      userEmail = "jph33@outlook.com";
      userName = "joshua hammer";
      extraConfig.push.autoSetupRemote = true;
    };

    chromium = {
      enable = true;
      package = pkgs.brave;
      commandLineArgs = [
        "--enable-features=UseOzonePlatform "
        "--ozone-platform=wayland"
        "--password-store=basic"
      ];
      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # vimium c
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      ];
    };
  };
}
