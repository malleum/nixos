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

    file.".config/onedrive/config".text = ''
      disable_notifications = "true"
      skip_dir = ".git*"
    '';
  };

  xdg = {
    inherit configHome;
    enable = true;
  };

  programs = {
    git = {
      enable = true;
      userEmail = "jph33@outlook.com";
      userName = "joshua hammer";
      extraConfig.push.autoSetupRemote = true;
    };
    qutebrowser = {
      enable = true;
      searchEngines = {
        "DEFAULT" = "https://search.brave.com/search?q={}";
        "d" = "https://search.duckduckgo.com/?q={}";
        "w" = "https://en.wikipedia.org/w/index.php?search={}";
        "g" = "https://www.google.com/search?q={}";
      };
      settings = {
        url = {
          start_pages = ["https://search.brave.com/"];
          default_page = "https://search.brave.com/";
        };
        colors = {
          webpage = {
            preferred_color_scheme = "dark";
          };
        };
      };
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
        "nacjakoppgmdcpemlfnfegmlhipddanj" # pdf vimium c
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      ];
    };
  };
}
