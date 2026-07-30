# jay, the primary compositor.
#
# This file is the module: packages, session units, and config wiring. The bulk
# of what used to live here now sits alongside it or in modules/scripts:
#   _config.nix      -- the ~570-line TOML document
#   _status.nix      -- the i3bar status feed (needs theme colours)
#   _lock.nix        -- the swaylock-effects lock screen (theme colours + wallpaper)
#   _tray-bridge.nix -- the wl-tray-bridge derivation
# and jay-audio-switch / jay-toggle-monitor / jay-power-menu /
# jay-window-switch are plain scripts in modules/scripts, auto-collected into
# flake packages by modules/packages/scripts.nix. They depend on nothing here,
# so they are runnable standalone: `nix run .#jay-power-menu`.
{inputs, ...}: {
  unify.modules.gui.nixos = {pkgs, ...}: let
    jayPkg = pkgs.jay;
  in {
    environment.systemPackages = [jayPkg pkgs.papirus-icon-theme];
    services.displayManager.sessionPackages = [jayPkg];

    # jay has no session manager, so graphical-session.target (which refuses
    # manual start) never activates and graphical-session user services like
    # cliphist never run. This target is started from jay's on-graphics-initialized
    # and pulls graphical-session.target in via BindsTo (dependency activation
    # bypasses RefuseManualStart).
    systemd.user.targets.jay-session = {
      description = "jay compositor session";
      bindsTo = ["graphical-session.target"];
      before = ["graphical-session.target"];
    };
  };

  unify.modules.gui.home = {
    config,
    hostConfig,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.stylix) base16Scheme;

    wallpaper = config.stylix.image;
    # pkgs.jay is nixpkgs' cached build; the `src` module overlays the
    # from-source flake input over it for hosts that want the tip.
    jayPkg = pkgs.jay;

    # EDID serial of each host's "left" monitor -- the one super-shift-m
    # toggles. Shared by the output config and the toggle keybinding.
    # manus: LG ULTRAGEAR (connector floats DP-1/DP-2, hence match-by-serial).
    # magnus: the TV (serial "1" is non-unique, paired with manufacturer "BBY"
    # in _config.nix's output match -- see the comment there).
    leftMonitorSerial =
      if hostConfig.name == "magnus"
      then "1"
      else "303142";

    wlTrayBridge = import ./_tray-bridge.nix {inherit pkgs;};
    jayStatus = import ./_status.nix {
      inherit pkgs;
      colors = base16Scheme;
    };
    jayLock = import ./_lock.nix {
      inherit pkgs wallpaper;
      colors = base16Scheme;
    };

    # The config-independent scripts, taken from the flake's own packages so
    # there is exactly one definition of each.
    inherit
      (inputs.self.packages.${pkgs.stdenv.hostPlatform.system})
      jay-audio-switch
      jay-toggle-monitor
      jay-power-menu
      jay-window-switch
      jay-osd
      ;

    jayConfig = import ./_config.nix {
      inherit pkgs leftMonitorSerial wallpaper jayStatus jayLock;
      hostName = hostConfig.name;
      colors = base16Scheme;
      browser = hostConfig.user.browser;
      browser2 = hostConfig.user.browser2;
      mod = "logo";
      audioSwitch = jay-audio-switch;
      monitorToggle = jay-toggle-monitor;
      powerMenu = jay-power-menu;
      windowSwitch = jay-window-switch;
      osd = jay-osd;
    };

    # Session daemons: supervised and scoped to the session, so PartOf stops
    # them when the target stops. The Signal and iamb units live in the `cht`
    # module, since a laptop that does not take chat should not pull them in.
    mkSessionUnit = import ./_session-unit.nix {inherit lib;};
  in {
    home.packages = [
      jayPkg
      # On PATH so jay-power-menu can lock with the themed screen. That script
      # lives in modules/scripts and is built by `pkgs.callPackage path {}`,
      # so it cannot be handed a theme-dependent derivation as an argument.
      jayLock
      pkgs.satty
      pkgs.playerctl
      pkgs.swayosd
      # rofi-driven pickers, bound to super-w / super-shift-w / super-ctrl-w
      pkgs.iwmenu
      pkgs.bzmenu
      pkgs.wiremix
      # GUI mixer, for when a real window beats a TUI. No GUI bluetooth app:
      # the super-shift-w rofi picker covers it.
      pkgs.pwvucontrol
      # keyboard pointer + output mirroring
      pkgs.wl-kbptr
      pkgs.wl-mirror
    ];

    systemd.user.services = {
      # The tray host. Needs privileged protocol access for jay_tray_v1, which
      # a keybinding got via `privileged = true`; as a unit it has to ask for
      # that itself through `jay run-privileged`.
      wl-tray-bridge = mkSessionUnit {
        description = "StatusNotifier tray bridge for jay";
        exec = "${jayPkg}/bin/jay run-privileged -- ${wlTrayBridge}/bin/wl-tray-bridge";
      };

      nm-applet = mkSessionUnit {
        description = "NetworkManager tray applet";
        exec = "${pkgs.networkmanagerapplet}/bin/nm-applet";
      };

      swaybg = mkSessionUnit {
        description = "Wallpaper";
        exec = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
      };

      # Renders the password prompt when polkit returns auth_admin. polkitd
      # itself only decides *whether* to ask; with no agent registered on the
      # session bus the request fails silently, which is why GUI privilege
      # escalation (nm-connection-editor on system connections, gparted,
      # fwupdmgr) did nothing at all.
      polkit-agent = mkSessionUnit {
        description = "polkit authentication agent";
        exec = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      };

      # Night light. jay exposes wlr-gamma-control to privileged clients only,
      # hence run-privileged rather than a [[clients]] rule.
      # Coordinates are Easley, SC.
      wlsunset = mkSessionUnit {
        description = "Day/night colour temperature";
        exec = "${jayPkg}/bin/jay run-privileged -- ${pkgs.wlsunset}/bin/wlsunset -l 34.83 -L -82.60 -t 3500 -T 6500";
      };

      # Draws the volume/brightness/caps-lock overlay. Needs layer-shell,
      # granted by a [[clients]] rule in _config.nix.
      #
      # --top-margin is a fraction of screen height and defaults to 0.85, i.e.
      # near the bottom. 0.05 puts the popup just under the bar. Which output
      # it lands on is decided per-invocation by jay-osd, not here.
      swayosd = mkSessionUnit {
        description = "On-screen volume/brightness indicator";
        exec = "${pkgs.swayosd}/bin/swayosd-server --top-margin 0.05";
      };
    };

    xdg.configFile."jay/config.toml".text = jayConfig;

    # wl-tray-bridge: use a real icon theme (Hicolor lacks named tray icons,
    # which is why nm-applet/pasystray showed the fallback "OBJ" placeholder).
    # `color` recolors symbolic SVGs to match the bar foreground.
    xdg.configFile."wl-tray-bridge/config.toml".text = ''
      scale = 1.0
      theme = "Papirus-Dark"

      [icon]
      color = "#${base16Scheme.base05}ff"
    '';

    # Satty config: save to downloads, copy to clipboard on save
    xdg.configFile."satty/config.toml".text = ''
      [general]
      save-after-copy = false
      copy-command = "wl-copy"
      output-filename = "$HOME/downloads/satty-%Y%m%d-%H%M%S.png"
    '';
  };
}
