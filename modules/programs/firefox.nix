{
  unify.modules.gui.nixos =
    { hostConfig, ... }:
    {
      system.userActivationScripts = {
        removeConflictingFiles = {
          text = ''
            rm -f ${hostConfig.user.homeDirectory}/.mozilla/firefox/default/search.json.mozlz4'
            rm -f ${hostConfig.user.homeDirectory}/.mozilla/firefox/default/search.json.mozlz4.bak'
          '';
        };
      };
    };

  unify.modules.gui.home =
    { pkgs, ... }:
    let
      myExtensions = with pkgs.nur.repos.rycee.firefox-addons; [
        bitwarden # Password manager
        darkreader # Dark mode for all websites
        # auto-accepts cookies, use only with privacy-badger & ublock-origin
        istilldontcareaboutcookies # Auto-removes cookie banners
        link-cleaner # Removes tracking parameters from URLs
        privacy-badger # Blocks trackers
        ublock-origin # Content blocker (ads, etc.)
        unpaywall # Finds free versions of academic papers
        tridactyl # Vim-like keybindings for Firefox
      ];

      # Combined and cleaned-up settings
      mySettings = {
        # --- Your Preferences ---
        "general.useragent.locale" = "en-US"; # Set language to US English
        "browser.shell.checkDefaultBrowser" = false; # Disable default browser check
        "browser.download.useDownloadDir" = true; # Save files to Downloads folder
        "browser.tabs.loadInBackground" = true; # Open new tabs in background
        "browser.ctrlTab.recentlyUsedOrder" = false; # Cycle tabs in visual order, not LRU
        "browser.ssb.enabled" = false; # Disable "Site Specific Browser" (PWA-like) feature
        "browser.sessionstore.resume_from_crash" = false; # Never auto-restore session after a crash
        "general.autoScroll" = false; # Middle-click auto-scroll
        "ui.systemUsesDarkTheme" = 1; # Enable Firefox's built-in dark UI
        "ui.key.menuAccessKey" = 0; # Disable Alt key opening menu

        # --- Disable Telemetry & Bloat ---
        "app.normandy.first_run" = false; # Disable Normandy (telemetry/studies)
        "app.shield.optoutstudies.enabled" = false; # Disable Shield (telemetry/studies)
        "app.normandy.api_url" = ""; # Disable Normandy endpoint
        "app.normandy.enabled" = false; # Disable Normandy
        "app.update.channel" = "default"; # Set update channel (managed by Nix)
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
        "toolkit.telemetry.enabled" = false; # Disable all telemetry
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
        "dom.forms.autocomplete.formautofill" = false; # Disable form autofill
        "privacy.donottrackheader.enabled" = true; # Enable "Do Not Track" header
        "network.connectivity-service.enabled" = false; # Disable Mozilla connectivity check

        "browser.newtabpage.enabled" = false; # Disables the complex new tab page
        "browser.newtab.preload" = false; # No need to preload it

        # --- Hardware Acceleration (Fix for Tearing) ---
        "gfx.webrender.all" = true; # Force-enable WebRender (Firefox's GPU renderer)
        "gfx.webrender.enabled" = true; # Just to be sure
        "media.ffmpeg.vaapi.enabled" = true; # This is the main one: enables VA-API (video decoding)
        "media.ffvpx.enabled" = false; # Disables the built-in VP8/VP9 decoder to force VA-API
        "media.rdd-process.enabled" = true; # Helps with sandboxing for video decoding

        "widget.wayland.opaque-region.enabled" = false; # Fix for Wayland (e.g., KDE) transparency bugs

        # --- Auto-Enable Extensions & Hide Prompts ---
        "extensions.startupScanScopes" = 1; # Allow extensions from user profile
        "extensions.showDomainRestrictions" = false; # Hide extension domain restriction prompts

        # --- Hide Bookmarks Bar ---
        "browser.toolbars.bookmarks.visibility" = "never"; # Always hide bookmarks toolbar

        # --- Disable Welcome, Hints, and Tours ---
        "browser.startup.homepage_override.mstone" = "ignore"; # Ignore "milestone" (update) welcome page
        "browser.tabs.firefox-view" = false; # Disable the "Firefox View" button
        "browser.tabs.firefox-view-newIcon" = false; # Disable the "Firefox View" icon
      };
    in
    {
      home.sessionVariables = {
        # Force Firefox to use Wayland
        MOZ_ENABLE_WAYLAND = "1";
        # Hardware acceleration
        MOZ_WEBRENDER = "1";
        MOZ_ACCELERATED = "1";
      };

      stylix.targets.firefox = {
        enable = true;
        profileNames = [ "default" ];
      };

      programs.firefox = {
        enable = true;
        package = pkgs.firefox-beta;

        profiles.default = {
          id = 0;
          isDefault = true;

          extensions.packages = myExtensions;

          search = {
            default = "Brave Search";
            engines = {
              "Brave Search" = {
                urls = [ { template = "https://search.brave.com/search?q={searchTerms}"; } ];
                icon = "${pkgs.brave}/share/pixmaps/brave.png";
                definedAliases = [ "@brave" ];
              };
              "google".metaData.hidden = false;
              # This removes the other default search engines
              "ddg".metaData.hidden = true;
              "bing".metaData.hidden = true;
            };
          };

          settings = mySettings;
        };
      };
    };
}
