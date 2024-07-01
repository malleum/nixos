{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  jetbrainNF = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
  py-mods = ps: with ps; [discordpy pip plotly pillow numpy django djangorestframework];
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
          element-desktop
          firefox
          losslesscut-bin
          obs-studio
          onedrive
          teams-for-linux
          virt-manager
          vlc
          vscode

          # sddm theme
          (callPackage ./aerial-sddm-theme.nix {}).aerial-sddm-theme

          protonup-ng
          wdisplays
          wine

          android-studio
          android-tools
          sdkmanager

          zoom-us
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
          nixos-shell
          fastfetch
          ripgrep
          killall
          choose
          unzip
          htop
          file
          wget
          tldr
          zip
          feh
          bat
          sd
          fd
          bc
          jq
        ]
        else []
      )
      ++ (
        if config.packages.programming.enable
        then [
          (python311.withPackages py-mods)
          luajitPackages.jsregexp
          lua-language-server
          pypy3
          clang-tools
          autoflake
          pyright
          flutter
          gnumake
          verilog
          erlang
          stylua
          gradle
          nodejs
          kotlin
          smlnj
          tetex
          black
          isort
          rustc
          cargo
          gleam
          ruby
          ruff
          dart
          nasm
          gcc
          gdb
          jdk
          nil
          lua
          go
        ]
        else []
      )
      ++ (
        if config.packages.etc.enable
        then [
          # nix
          inputs.nix-alien.packages.${pkgs.system}.nix-alien
          nix-output-monitor
          nix-prefetch-github
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
          p7zip
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
