{
  pkgs,
  inputs,
  ...
}: let
  username = "joshammer";
  description = "Joshua Hammer";
  image = /home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg;
in {
  imports = [
    ./hardware-configuration.nix
    inputs.stylix.nixosModules.stylix # for stylix to do all its styling in the background
  ];

  # TODO: This section will need to be replaced if your device doesn't support efi
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "brick"; # computer hostname
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.utf8";

  nix.settings.experimental-features = ["flakes" "nix-command"];

  system = {
    stateVersion = "22.11"; # NOTE: DON'T CHANGE THIS
    autoUpgrade.enable = true;
  };

  programs = {
    fish.enable = true;
    nh = {
      # nix helper
      enable = true;
      clean.enable = true;
      flake = "~/.config/nixos"; # or wherever you put your config files
    };
    nix-ld = {
      enable = true; # another nix thing to help patch binaries that break
      libraries = with pkgs; [glib];
    };
    steam = {
      # yay
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    chromium = {
      enable = true;
      extraOpts = {
        "BraveVPNDisabled" = true;
        "BraveWalletDisabled" = true; # wallet is annoying
      };
    };

    hyprland.enable = true;
    waybar.enable = true; # bar
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk]; # this helps hyprland render gtk things
    };
  };

  services = {
    openssh.enable = true; # ssh
    printing.enable = true;
    unclutter.enable = true; # hide mouse when inactive

    pipewire = {
      # audio
      enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # "login" manager
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "hyprland";
    };
  };

  security = {
    pam.services.swaylock = {}; # these 2 lines make the swaylock work properly as a lock screen program
    rtkit.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
    acpilight.enable = true; # keyboard backlighting
    pulseaudio.enable = false; # old audio program
  };

  users = {
    defaultUserShell = pkgs.fish;

    # NOTE: this is how nix does string interpolation
    # it will literally become `users.joshammer = {` (for me lol)
    users."${username}" = {
      isNormalUser = true;
      inherit description; # inherits the full name from the let-in section
      extraGroups = ["audio" "networkmanager" "video" "wheel"]; # wheel lets you use sudo
    };
  };

  stylix = {
    enable = true;
    image = image; # generate color scheme from image (that will we set to be the background)
    polarity = "dark";

    opacity = {
      terminal = 0.95;
      popups = 0.9;
    };

    fonts = {
      sizes = {terminal = 13;};
      monospace = {
        package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];}; # NOTE: best font
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };

    # NOTE: fish takes forever to load inside tmux when either fish or tmux are styled by stylix
    # so I just style them manually
    targets = {fish.enable = false;};
  };

  home-manager = {
    # to manage some of the config files
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users."${username}" = import ./home.nix; # NOTE: could put this in this file too, but readability moment
  };

  environment = {
    variables = {
      EDITOR = "nvim"; # env vars
      VISUAL = "nvim";
      BROWSER = "brave";
      TERMINAL = "foot";

      # for hyprland
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

    shellAliases = {
      cat = "bat";
      ls = "eza --icons";
    };

    systemPackages = with pkgs; [
      discord
      obs-studio
      teams-for-linux
      vlc
      vscode

      protonup-ng # installer for proton for steam

      wdisplays # mess with monitor positioning

      prismlauncher # minecraft launcher

      # office + related
      libreoffice
      hunspellDicts.en-us
      hunspell

      pandoc # document converter
      gimp # paint but insane

      # sound control
      pavucontrol
      pulsemixer
      pasystray

      # styling
      nwg-look
      gtk4
      gtk3

      inputs.fix-python.packages.${pkgs.system}.default # fix python modules that have the libc++ error
      inputs.alejandra.defaultPackage.${pkgs.system} # nix formatter
      ripgrep # rg: better grep
      killall # kill all of a certain application
      ikill # interactive kill
      choose # better cut
      unzip
      htop # task manager
      btop # better task manager
      wget # curl alternative
      tldr # tldr a command
      zip
      bat # better cat
      sd # better tr
      fd # better find
      bc # basic calculator
      jq # tool for json parsing

      clang-tools
      python3Full
      pyright
      nodejs
      isort
      ruff
      dart
      gcc
      jdk
      lua

      # cli
      acpi # battery
      libnotify # send notifications
      libqalculate # qalc terminal calculator
      neofetch # pc stats
      fastfetch # better pc stats
      networkmanagerapplet # manage network

      # wayland
      hyprshot # screenshot
      swappy # screenshot editor
      swaylock # lockscreen
      swww # wallpaper
      cliphist # clipboard stuff
      wl-clip-persist
      wl-clipboard

      # work stuff
      awscli2
      openvpn
      pipx
      pre-commit
      poetry
    ];
  };

  fonts.packages = [pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];}];
}
