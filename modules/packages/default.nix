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
          firefox
          losslesscut-bin
          obs-studio
          onedrive
          vesktop
          vlc

          prismlauncher
          protonup-ng
          quickemu
          wdisplays
          wine

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
          cargo
          clang-tools
          gcc
          gdb
          gnumake
          go
          gradle
          jdk
          julia
          kotlin
          lua
          nodejs
          pyright
          python3Full
          python311
          rustc
          typst
          zig
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
          libnotify
          libqalculate
          networkmanagerapplet
          nitch
          nmap
          openssl
          speedtest-cli
          spice-gtk

          # wayland
          hyprpaper
          hyprpicker
          inputs.hyprqt.packages.${pkgs.system}.default
          wl-clipboard
          wtype
          xwaylandvideobridge

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
