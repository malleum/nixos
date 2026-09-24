{inputs, ...}: {
  unify.modules.gui.nixos = {
    pkgs,
    hostConfig,
    ...
  }: let
    themes = import ./_themes.nix {
      inherit pkgs;
      name = hostConfig.name;
    };
    theme = "cybertruck";
  in {
    imports = [inputs.stylix.nixosModules.stylix];

    stylix = {
      enable = true;
      enableReleaseChecks = false;
      image = themes.${theme}.image;
      base16Scheme = themes.${theme}.base16Scheme;

      polarity = "dark";

      opacity = {
        terminal = 0.85;
        popups = 0.9;
      };
      cursor = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 32;
      };

      fonts = {
        sizes = {
          terminal = 13;
        };
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.noto-fonts;
          name = "NotoSans";
        };
        serif = {
          package = pkgs.noto-fonts;
          name = "NotoSerif";
        };
      };

      targets = {
        kmscon.enable = false;
      };
    };
  };

  unify.modules.gui.home = {
    lib,
    pkgs,
    ...
  }: {
    # Cursor theme. Only meaningful with a display, and its name/package come
    # from stylix.cursor above — so this belongs to the gui module, not the
    # global home config: headless hosts get no stylix, and enabling it there
    # leaves home.pointerCursor.name undefined and fails to evaluate.
    home.pointerCursor.enable = true;

    # Unify GTK app icons (pavucontrol, nm-connection-editor, file dialogs)
    # with the tray. Papirus-Dark is a complete set with light-on-dark panel
    # icons. Stylix already sets gtk.theme/enable; it does not set iconTheme.
    gtk.iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    stylix.enableReleaseChecks = false;

    stylix.targets = {
      bat.enable = false; # tokyonight, set in modules/programs/cli.nix
      # Two separate options, and both are needed. `hyprpaper.enable` is the
      # target that writes hyprpaper's config; `hyprland.hyprpaper.enable` is
      # what actually turns the daemon on, and it auto-enables from
      # stylix.image being set. With only the first one off, hyprpaper ran with
      # no wallpaper to paint, aborted once per login and left a coredump.
      #
      # Nothing here wants it: jay draws the wallpaper with swaybg
      # (modules/programs/jay/default.nix) and hyprland uses awww
      # (modules/programs/hypr.nix).
      hyprland.hyprpaper.enable = lib.mkForce false;
      hyprpaper.enable = lib.mkForce false;
      rofi.enable = false;
      tmux.enable = false;
      waybar.enable = false;
    };
  };
}
