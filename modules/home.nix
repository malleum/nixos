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
    git = {
      enable = true;
      userEmail = "jph33@outlook.com";
      userName = "Joshua Hammer";
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
        "gfbliohnnapiefjpjlpjnehglfpaknnc" # surfingkeys
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      ];
    };
  };
}
