# Firefox, as two profiles built from the same parts:
#
#   default  every gui host. Personal.
#   work     wrk hosts only. Same extensions, settings and search engines, but
#            its own cookies, logins, history and bookmarks, so claude.ai (or
#            anything else) can be signed in to a work account here and a
#            personal one there, both at once, each remembering who it is.
#            It runs as its own window: `firefox-work`, mod+ctrl+shift+b, or
#            "Firefox (Work)" in rofi. Orange chrome and a blue visiostack tag in front of
#            the address bar tell the two apart at a glance.
let
  extensionsFor = pkgs:
    with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden # Password manager
      darkreader # Dark mode for all websites
      istilldontcareaboutcookies # Auto-removes cookie banners
      link-cleaner # Removes tracking parameters from URLs
      privacy-badger # Blocks trackers
      ublock-origin # Content blocker (ads, etc.)
      unpaywall # Finds free versions of academic papers
      tridactyl # Vim-like keybindings for Firefox
      youtube-shorts-block # Hide/normalize YouTube Shorts
    ];

  # Combined and cleaned-up settings
  settings = {
    # --- Your Preferences ---
    "general.useragent.locale" = "en-US"; # Set language to US English
    "browser.shell.checkDefaultBrowser" = false; # Disable default browser check
    "browser.download.always_ask_before_handling_new_types" = true; # Never auto-open downloads (csv etc.) — always ask/save, no LibreOffice autolaunch
    "browser.ctrlTab.recentlyUsedOrder" = false; # Cycle tabs in visual order, not LRU
    "browser.ssb.enabled" = false; # Disable "Site Specific Browser" (PWA-like) feature
    "browser.sessionstore.resume_from_crash" = false; # Never auto-restore session after a crash
    "ui.systemUsesDarkTheme" = 1; # Enable Firefox's built-in dark UI
    "ui.key.menuAccessKey" = 0; # Disable Alt key opening menu

    # --- Disable Telemetry & Bloat ---
    "app.normandy.first_run" = false; # Disable Normandy (telemetry/studies)
    "app.shield.optoutstudies.enabled" = false; # Disable Shield (telemetry/studies)
    "app.normandy.api_url" = ""; # Disable Normandy endpoint
    "app.normandy.enabled" = false; # Disable Normandy
    "extensions.update.enabled" = false; # Disable extension auto-updates (managed by Nix)
    "browser.discovery.enabled" = false; # Disable "Recommendations" feature
    "browser.startup.homepage" = "about:newtab"; # Set homepage to new tab
    "browser.newtabpage.activity-stream.default.sites" = ""; # Clear default top sites
    "browser.newtabpage.activity-stream.feeds.topsites" = false; # Disable top sites on new tab
    "browser.newtabpage.activity-stream.showSponsored" = false; # Disable sponsored content
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false; # Disable sponsored top sites
    "browser.newtabpage.activity-stream.feeds.telemetry" = false; # Disable new tab telemetry
    "browser.newtabpage.activity-stream.telemetry" = false; # Disable new tab telemetry
    "browser.uitour.enabled" = false; # Disable "Welcome" tour
    "browser.aboutConfig.showWarning" = false; # Disable about:config warning
    "browser.vpn_promo.enabled" = false; # Disable Mozilla VPN promo
    "datareporting.policy.dataSubmissionEnabled" = false; # Disable data reporting
    "datareporting.healthreport.uploadEnabled" = false; # Disable health report upload
    "toolkit.telemetry.unified" = false; # Disable unified telemetry
    "toolkit.telemetry.server" = "data:,"; # Point telemetry server to nowhere
    "toolkit.telemetry.archive.enabled" = false; # Disable telemetry archive
    "toolkit.telemetry.newProfilePing.enabled" = false; # Disable telemetry ping
    "toolkit.telemetry.shutdownPingSender.enabled" = false; # Disable telemetry ping
    "toolkit.telemetry.updatePing.enabled" = false; # Disable telemetry ping
    "toolkit.telemetry.bhrPing.enabled" = false; # Disable telemetry ping
    "toolkit.telemetry.firstShutdownPing.enabled" = false; # Disable telemetry ping
    "browser.ping-centre.telemetry" = false; # Disable ping centre telemetry
    "toolkit.telemetry.reportingpolicy.firstRun" = false; # Disable telemetry reporting
    "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false; # Disable telemetry ping

    # --- Disable Annoying URL Bar Quick Actions ---
    "browser.urlbar.quickactions.enabled" = false; # Disable quick actions (e.g., 'view history')
    "browser.urlbar.quickactions.showPrefs" = false; # Hide quick action preferences
    "browser.urlbar.shortcuts.quickactions" = false; # Disable quick action shortcuts
    "browser.urlbar.suggest.quickactions" = false; # Disable quick action suggestions
    "browser.urlbar.showSearchSuggestionsFirst" = false; # Show history/bookmarks before search

    "browser.urlbar.trimURLs" = false; # Show https://, www., etc.
    "browser.urlbar.maxRichResults" = 15; # Show more dropdown results
    "browser.search.widget.inNavBar" = false; # Remove separate search bar (makes URL bar wider)

    # --- Privacy ---
    "browser.contentblocking.category" = "standard"; # "strict" can break sites
    "privacy.donottrackheader.enabled" = true; # Enable "Do Not Track" header
    "network.connectivity-service.enabled" = false; # Disable Mozilla connectivity check

    "browser.newtabpage.enabled" = false; # Disables the complex new tab page
    "browser.newtab.preload" = false; # No need to preload it

    # --- Hardware Acceleration (Fix for Tearing) ---
    "gfx.webrender.all" = true; # Force-enable WebRender (Firefox's GPU renderer)
    "gfx.webrender.enabled" = true; # Just to be sure
    "media.ffmpeg.vaapi.enabled" = true; # VA-API hardware video decode
    "media.ffvpx.enabled" = true; # Software VP8/VP9 fallback when VA-API can't handle codec
    "media.webrtc.pipewire.enabled" = true;

    # --- Wayland-specific ---
    "widget.wayland-dmabuf-vaapi.enabled" = true; # Zero-copy VA-API → compositor via DMA-BUF

    # --- Auto-Enable Extensions & Hide Prompts ---
    "extensions.startupScanScopes" = 1; # Allow extensions from user profile
    "extensions.autoDisableScopes" = 0; # Don't auto-disable any extension scope on install
    "extensions.showDomainRestrictions" = false; # Hide extension domain restriction prompts

    # --- DRM (Widevine) auto-accept ---
    "media.eme.enabled" = true; # Master EME (DRM) switch — pre-accept
    "media.gmp-widevinecdm.autoupdate" = true; # Keep Widevine current
    "media.gmp-manager.updateEnabled" = true; # Allow GMP (Widevine etc.) downloads

    # --- Suppress mailto / protocol-handler registration popups ---
    "network.protocol-handler.external.mailto" = false; # Don't hand mailto to external app
    "gecko.handlerService.allowRegisterFromDifferentHost" = false; # Block cross-host handler registration

    # --- Hide Bookmarks Bar ---
    "browser.toolbars.bookmarks.visibility" = "never"; # Always hide bookmarks toolbar

    # --- Disable Welcome, Hints, and Tours ---
    "browser.startup.homepage_override.mstone" = "ignore"; # Ignore "milestone" (update) welcome page
    "browser.tabs.firefox-view" = false; # Disable the "Firefox View" button
    "browser.tabs.firefox-view-newIcon" = false; # Disable the "Firefox View" icon

    # --- Disable Quick Find (Links Only) ---
    "accessibility.typeaheadfind.manual" = false; # Disable ' and / typeahead find shortcuts
  };

  searchFor = pkgs: {
    default = "Brave Search";
    engines = {
      "brave" = {
        urls = [{template = "https://search.brave.com/search?q={searchTerms}";}];
        icon = "${pkgs.brave}/share/pixmaps/brave.png";
        definedAliases = ["@brave"];
      };
      "wikipedia" = {
        urls = [{template = "https://en.wikipedia.org/wiki/Special:Search?search={searchTerms}";}];
        definedAliases = ["@w"];
      };
      "NixOS Packages" = {
        urls = [{template = "https://search.nixos.org/packages?query={searchTerms}";}];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = ["@np"];
      };
      "NixOS Options" = {
        urls = [{template = "https://search.nixos.org/options?query={searchTerms}";}];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = ["@no"];
      };
      "Home Manager Options" = {
        urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";}];
        definedAliases = ["@hm"];
      };
      "google".metaData.hidden = false;
      # This removes the other default search engines
      "ddg".metaData.hidden = true;
      "bing".metaData.hidden = true;
    };
  };

  # Everything the two profiles have in common.
  sharedProfile = pkgs: {
    extensions = {
      packages = extensionsFor pkgs;
      force = true; # Overwrite extensions.json so Nix-managed addons enable on first run
    };
    search = searchFor pkgs;
    inherit settings;
  };

  # Firefox rewrites these itself and then prefers its own copy over ours:
  # search.json pins the old engine list, handlers.json the per-type download
  # actions (csv -> LibreOffice etc.; the always_ask pref takes over once it's gone).
  resetProfileFiles = lib: home: profile:
    lib.hm.dag.entryBefore ["writeBoundary"] ''
      run rm -f ${home}/.mozilla/firefox/${profile}/search.json.mozlz4
      run rm -f ${home}/.mozilla/firefox/${profile}/search.json.mozlz4.bak
      run rm -f ${home}/.mozilla/firefox/${profile}/handlers.json
    '';
in {
  flake.modules.homeManager.gui = {
    pkgs,
    hostConfig,
    lib,
    ...
  }: {
    home.activation.resetFirefoxProfileFiles = resetProfileFiles lib hostConfig.user.homeDirectory "default";

    stylix.targets.firefox = {
      enable = true;
      profileNames = ["default"];
    };

    # Loaded by tridactyl via the native messenger (`:source` to reload)
    xdg.configFile."tridactyl/tridactylrc".text = ''
      bind / fillcmdline find
      bind ? fillcmdline find --reverse
      bind n findnext --search-from-view
      bind N findnext --search-from-view --reverse
    '';

    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
      configPath = ".mozilla/firefox";
      nativeMessagingHosts = [pkgs.tridactyl-native]; # Lets tridactyl read tridactylrc

      profiles.default =
        sharedProfile pkgs
        // {
          id = 0;
          isDefault = true;
        };
    };
  };

  flake.modules.homeManager.wrk = {
    config,
    hostConfig,
    lib,
    pkgs,
    ...
  }: let
    c = config.lib.stylix.colors.withHashtag;
    accent = c.base09; # orange in every scheme we use
    tag = c.base0D; # blue

    # `--name` sets the Wayland app_id (and X11 WM_CLASS), so the compositor,
    # rofi and the bar see a separate app rather than a second Firefox window.
    # Two profiles run side by side as two processes; that needs nothing extra.
    firefox-work = pkgs.writeShellScriptBin "firefox-work" ''
      exec ${config.programs.firefox.finalPackage}/bin/firefox -P work --name firefox-work "$@"
    '';
  in {
    home.packages = [firefox-work];

    xdg.desktopEntries.firefox-work = {
      name = "Firefox (Work)";
      genericName = "Web Browser";
      exec = "firefox-work %U";
      icon = "firefox";
      terminal = false;
      categories = ["Network" "WebBrowser"];
      settings.StartupWMClass = "firefox-work";
    };

    home.activation.resetFirefoxWorkProfileFiles = resetProfileFiles lib hostConfig.user.homeDirectory "work";

    stylix.targets.firefox.profileNames = ["work"];

    programs.firefox.profiles.work = lib.recursiveUpdate (sharedProfile pkgs) {
      id = 1;
      settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true; # read userChrome.css

      # Only the chrome changes, never page content. The tab strip is tinted
      # orange, the selected tab and the address bar are outlined in it, and a
      # blue visiostack tag sits in front of the address bar.
      userChrome = ''
        :root {
          --work-accent: ${accent};
          --work-tint: color-mix(in srgb, ${accent} 38%, ${c.base00});
        }

        #navigator-toolbox {
          background-color: var(--work-tint) !important;
          border-top: 3px solid var(--work-accent) !important;
        }

        .tab-background:is([selected], [multiselected]) {
          box-shadow: inset 0 2px 0 var(--work-accent) !important;
        }

        #urlbar-background {
          border: 1px solid var(--work-accent) !important;
        }

        #urlbar-container::before {
          content: "visiostack";
          align-self: center;
          margin-inline-end: 6px;
          padding: 2px 6px;
          border-radius: 4px;
          background-color: ${tag};
          color: ${c.base00};
          font-weight: bold;
          font-size: 0.85em;
          letter-spacing: 0.05em;
        }
      '';
    };
  };
}
