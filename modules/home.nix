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
    enable = true;
    inherit configHome;
  };

  programs = {
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
        # "--enable-features=UseOzonePlatform "
        # "--ozone-platform=wayland"
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
