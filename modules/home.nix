{
  pkgs,
  lib,
  inputs,
  ...
}: let
  username = "joshammer";
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";
  glfwww = inputs.waywall.packages.${pkgs.system}.glfw;
in {
  imports = [./homemodules];
  stylix.targets = {
    fish.enable = false;
    hyprpaper.enable = lib.mkForce false;
    nixvim.enable = false;
    tmux.enable = false;
  };

  home = {
    inherit username homeDirectory;
    enableNixpkgsReleaseCheck = false;
    stateVersion = "23.11";

    file = {
      ".config/onedrive/config".text = ''
        disable_notifications = "true"
        skip_dir = ".git*"
      '';
      ".local/lib64/libglfw.so".source = "${glfwww}/lib/libglfw.so";
    };
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
