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
    glfwww = inputs.waywall.packages.${pkgs.system}.glfw;
    ninjabrainbot = inputs.waywall.packages.${pkgs.system}.ninjabrainbot;
    waywall-git = inputs.waywall.packages.${pkgs.system}.waywall;
    ifopt = opt: lst:
      if opt
      then lst
      else [];
  in
    lib.mkIf config.packages.enable {
      environment.systemPackages = with pkgs;
        (
          (
            if config.networking.hostName == "malleum"
            then [globalprotect-openconnect]
            else []
          )
          ++ ifopt config.packages.gui.enable
          [
            cherry-studio
            code-cursor-fhs
            haguichi
            losslesscut-bin
            lumafly
            quickemu
            vesktop
            vlc
            wdisplays

            prismlauncher
            waywall-git
            glfwww
            ninjabrainbot
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
            alejandra
            fastfetch
            killall
            ripgrep
            choose
            btop
            file
            fzf
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
            gcc
            gdb
            gnumake
            go
            gradle
            iogii
            jdk21
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
            claude-code
            ffmpeg
            gemini-cli
            imagemagick
            libnotify
            libqalculate
            magic-wormhole
            networkmanagerapplet
            nitch
            nmap
            openssl
            speedtest-cli
            spice-gtk

            # wayland
            hyprland-qtutils
            hyprpicker
            kdePackages.xwaylandvideobridge
            qt6.qtwayland
            swww
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
