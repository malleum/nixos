{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
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
          firefox
          losslesscut-bin
          obs-studio
          onedrive
          vesktop
          virt-manager
          vlc
          vscodium
          zathura

          protonup-ng
          quickemu
          wdisplays
          wine

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
          btop
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
          gcc-arm-embedded # arm-none-eabi-gcc -c
          clang-tools
          python3Full
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
          julia
          rustc
          nasm
          nmap
          ruby
          gcc
          gdb
          jdk
          lua
          nil
          zig
          go
        ]
        else []
      )
      ++ (
        if config.packages.etc.enable
        then [
          # nix
          inputs.nix-alien.packages.${pkgs.system}.nix-alien
          inputs.deploy.packages.${pkgs.system}.default
          nix-prefetch-github
          nix-output-monitor
          nixos-shell
          nvd

          # cli
          acpi
          arp-scan
          fping
          ikill
          libnotify
          libqalculate
          neofetch
          networkmanagerapplet
          nitch
          openssl
          patchelf
          speedtest-cli
          spice-gtk
          valgrind
          wtype

          # xorg
          arandr
          betterlockscreen
          xclip
          xorg.xinit
          xorg.xkbcomp
          xorg.xrandr

          # wayland
          hyprpicker
          hyprpaper
          wl-clipboard
          xwaylandvideobridge
          inputs.hyprqt.packages.${pkgs.system}.default

          # lols
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

    fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];
  };
}
