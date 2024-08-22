{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  jetbrainNF = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
in {
  options.packages = {
    enable = lib.mkEnableOption "enables packages";
    minimus.enable = lib.mkEnableOption "enables required packages";
    programming.enable = lib.mkEnableOption "enables required packages";
    etc.enable = lib.mkEnableOption "enables other packages";
    gui.enable = lib.mkEnableOption "enables gui packages";
  };

  config = lib.mkIf config.packages.enable {
    environment.systemPackages = with pkgs;
      (
        if config.packages.gui.enable
        then [
          ### gui

          # main
          discord
          vesktop
          firefox
          losslesscut-bin
          obs-studio
          onedrive
          teams-for-linux
          virt-manager
          vlc
          vscodium

          # sddm theme
          (callPackage ./aerial-sddm-theme.nix {})
          (catppuccin-sddm.override {
            flavor = "mocha";
            font = "JetBrainsMono Nerd Font Mono";
            fontSize = "11";
            # background = "${/home/joshammer/OneDrive/Documents/Stuff/pics/cybertruckLego.jpg}";
            loginBackground = true;
          })

          protonup-ng
          wdisplays
          wine

          # android-studio android-tools sdkmanager

          prismlauncher

          # office
          hunspellDicts.en-us
          libreoffice
          hunspell
          pandoc
          gimp

          # sound
          pavucontrol
          pulsemixer
          pasystray

          # sddm theme
          libsForQt5.phonon-backend-gstreamer
          libsForQt5.qt5.qtgraphicaleffects
          libsForQt5.qt5.qtmultimedia
          gst_all_1.gst-plugins-good

          # styling
          nwg-look
          gtk4
          gtk3
        ]
        else []
      )
      ++ (
        if config.packages.minimus.enable
        then [
          inputs.fix-python.packages.${pkgs.system}.default
          inputs.alejandra.defaultPackage.${pkgs.system}
          inputs.nixvim.packages.${pkgs.system}.default
          inputs.rip2.packages.${pkgs.system}.default
          fastfetch
          killall
          ripgrep
          choose
          file
          htop
          ouch
          tldr
          wget
          bat
          feh
          bc
          fd
          jq
          sd
        ]
        else []
      )
      ++ (
        if config.packages.programming.enable
        then [
          luajitPackages.jsregexp
          lua-language-server
          clang-tools
          python3Full
          autoflake
          flutter
          gnumake
          pyright
          verilog
          erlang
          gradle
          kotlin
          nodejs
          stylua
          black
          cargo
          gleam
          isort
          pypy3
          rustc
          smlnj
          tetex
          dart
          nasm
          ruby
          ruff
          gcc
          gdb
          jdk
          lua
          nil
          go
        ]
        else []
      )
      ++ (
        if config.packages.etc.enable
        then [
          # nix
          inputs.nix-alien.packages.${pkgs.system}.nix-alien
          nix-prefetch-github
          nix-output-monitor
          nixos-shell
          nvd

          # cli
          acpi
          ikill
          latexrun
          libnotify
          libqalculate
          libsForQt5.okular
          neofetch
          networkmanagerapplet
          nitch
          patchelf
          speedtest-cli
          spice-gtk
          texliveTeTeX
          valgrind
          wtype

          # xorg
          arandr
          betterlockscreen
          xclip
          xorg.xkbcomp
          xorg.xrandr

          # wayland
          cliphist
          grim
          hyprpicker
          hyprshot
          slurp
          swappy
          sway-contrib.grimshot
          swaylock
          swww
          mpvpaper
          wl-clip-persist
          wl-clipboard
          xwaylandvideobridge

          # lols
          cava
          cmatrix
          cowsay
          fortune
          lolcat
          nyancat
          sl

          # visio
          awscli2
          openvpn
          pipx
          pre-commit
          poetry
        ]
        else []
      );

    fonts.packages = [jetbrainNF];
  };
}
