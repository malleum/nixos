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

  config = let
    iogii = pkgs.callPackage ./iogii.nix {};
    ifopt = opt: lst:
      if opt
      then lst
      else [];
  in
    lib.mkIf config.packages.enable {
      environment.systemPackages = with pkgs;
        (
          ifopt config.packages.gui.enable
          [
            code-cursor-fhs
            keyd
            losslesscut-bin
            obs-studio
            onedrive
            quickemu
            vlc
            vesktop
            wdisplays
            tiled
            godot
            haguichi
            logmein-hamachi
            lumafly

            prismlauncher
            protonup-ng
            lutris
            bottles
            wine
            winetricks

            vulkan-tools
            vulkan-loader
            vulkan-validation-layers

            libva
            libva-utils

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
        )
        ++ (
          ifopt config.packages.minimus.enable
          [
            inputs.fix-python.packages.${pkgs.system}.default
            inputs.nixvim.packages.${pkgs.system}.default
            alejandra
            fastfetch
            killall
            ripgrep
            choose
            btop
            file
            htop
            ouch
            rip2
            tldr
            wget
            bat
            feh
            bc
            fd
            jq
            sd
          ]
        )
        ++ (
          ifopt config.packages.programming.enable
          [
            cargo
            clang-tools
            clojure
            gcc
            gdb
            gnumake
            go
            gradle
            iogii
            jdk21
            julia
            kotlin
            leiningen
            lua
            nodejs
            python3
            rustc
            typst
            zig
          ]
        )
        ++ (
          ifopt config.packages.etc.enable
          [
            # nix
            inputs.nix-alien.packages.${pkgs.system}.nix-alien
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
            wirelesstools # apparently needed for wt 🤷‍♀

            # wayland
            hyprland-qtutils
            hyprpaper
            hyprpicker
            kdePackages.xwaylandvideobridge
            qt6.qtwayland
            wl-clipboard
            wl-crosshair
            wtype
            wlrctl

            xdotool

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
          ]
        );

      fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];
    };
}
