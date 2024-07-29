{
  pkgs,
  username,
  ...
}: let
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";
in {
  stylix.targets = {
    tmux.enable = false; # see previous stylix fish tmux comment
    fish.enable = false;
  };

  home = {
    inherit username homeDirectory;
    enableNixpkgsReleaseCheck = false;
    stateVersion = "24.05";

    file = {
      # NOTE: I like doing this because then I can keep the hyprland configuration in my general git repo, and also keep it in the default hyprland.conf syntax
      # but you could get rid of it and just configure hyprland with nix syntax instead using the home manager `hyprland.settings` or something
      ".config/hypr/hyprland.conf".text = ''
        source = ~/.config/nixos/hyprland.conf
      ''; # basically just writes a file to where hyprland expects its config file to be, and tells it to source the config file in this repo
    };
  };

  xdg = {
    inherit configHome;
    enable = true;
  };

  services.dunst.enable = true; # Notifications

  # packages only for this user
  home.packages = with pkgs; [
    # fish stuff
    fishPlugins.autopair # helps for (), [], {}
    fishPlugins.colored-man-pages # epic
    fishPlugins.grc # colorizes command outputs
    fishPlugins.puffer # does `../../` when typing `...`
    fishPlugins.tide # prompt, use 16 colors option to have colorscheme match
    eza # better ls
    fzf # better searching for recent commands with Contrl+r
    grc # colorizes command outputs

    # startup script
    (pkgs.callPackage ./startup.nix {wallpaper = "${config.stylix.image}";})
  ];

  programs = {
    fish = {
      enable = true;
      shellInit = ''
        fish_vi_key_bindings
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    };
    zoxide.enable = true; # `z` a `cd` with teleportation

    tmux = {
      enable = true;
      terminal = "tmux-256color";
      keyMode = "vi";
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [
        sensible
        tilish
        tmux-fzf
      ];
    };

    # foot, alacritty, and kitty are all terminals
    # I like foot the best because it is the simplest (but it doesn't work on X, hence why I have the others)
    foot = {
      enable = true;
      settings = {
        main.term = "xterm-256color";
        mouse.hide-when-typing = "yes";
      };
    };
    alacritty.enable = true;
    kitty.enable = true;

    git = {
      enable = true;
      userEmail = "jph33@outlook.com"; # TODO: setup git login
      userName = "Joshua Hammer";
      # TODO: and then use `gh auth login` to actually login
      # I usually have problems installing `gh` declaratively, so I usually just do a `nix profile install gh`
    };

    # Brave and its settings
    chromium = {
      enable = true;
      package = pkgs.brave;
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--password-store=basic"
      ];
      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
        "gfbliohnnapiefjpjlpjnehglfpaknnc" # surfingkeys
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      ];
    };

    # search and run apps
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      location = "center";
    };
  };
}
