{
  unify.modules.gui.home = {pkgs, ...}: let
    myExtensions = with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden
      darkreader
      # auto-accepts cookies, use only with privacy-badger & ublock-origin
      istilldontcareaboutcookies
      link-cleaner
      privacy-badger
      ublock-origin
      unpaywall
      vimium
    ];

    # Combined and cleaned-up settings
    mySettings = {
      # --- Your Preferences ---
      "general.useragent.locale" = "en-US";
      "browser.shell.checkDefaultBrowser" = false;
      "browser.download.useDownloadDir" = true;
      "browser.tabs.loadInBackground" = true;
      "browser.ctrlTab.recentlyUsedOrder" = false;
      "general.autoScroll" = false; # Middle-click auto-scroll
      "ui.systemUsesDarkTheme" = 1; # Enable Firefox's built-in dark UI

      # --- Disable Telemetry & Bloat ---
      "app.normandy.first_run" = false;
      "app.shield.optoutstudies.enabled" = false;
      "app.normandy.api_url" = "";
      "app.normandy.enabled" = false;
      "app.update.channel" = "default"; # Disable updates (pointless in Nix)
      "extensions.update.enabled" = false;
      "browser.discovery.enabled" = false;
      "browser.startup.homepage" = "about:newtab";
      "browser.newtabpage.activity-stream.default.sites" = "";
      "browser.newtabpage.activity-stream.feeds.topsites" = false;
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.newtabpage.activity-stream.feeds.telemetry" = false;
      "browser.newtabpage.activity-stream.telemetry" = false;
      "browser.uitour.enabled" = false;
      "browser.aboutConfig.showWarning" = false;
      "browser.vpn_promo.enabled" = false;
      "datareporting.policy.dataSubmissionEnabled" = false;
      "datareporting.healthreport.uploadEnabled" = false;
      "toolkit.telemetry.unified" = false;
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.server" = "data:,";
      "toolkit.telemetry.archive.enabled" = false;
      "toolkit.telemetry.newProfilePing.enabled" = false;
      "toolkit.telemetry.shutdownPingSender.enabled" = false;
      "toolkit.telemetry.updatePing.enabled" = false;
      "toolkit.telemetry.bhrPing.enabled" = false;
      "toolkit.telemetry.firstShutdownPing.enabled" = false;
      "browser.ping-centre.telemetry" = false;
      "toolkit.telemetry.reportingpolicy.firstRun" = false;
      "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false;

      # --- Disable Annoying URL Bar Quick Actions ---
      "browser.urlbar.quickactions.enabled" = false;
      "browser.urlbar.quickactions.showPrefs" = false;
      "browser.urlbar.shortcuts.quickactions" = false;
      "browser.urlbar.suggest.quickactions" = false;
      "browser.urlbar.showSearchSuggestionsFirst" = false;

      "browser.urlbar.trimURLs" = false; # Show https://, www., etc.
      "browser.urlbar.maxRichResults" = 15; # Show more dropdown results

      # --- Privacy ---
      "browser.contentblocking.category" = "standard"; # "strict" can break sites
      "dom.forms.autocomplete.formautofill" = false;
      "privacy.donottrackheader.enabled" = true;
      "network.connectivity-service.enabled" = false;

      "browser.newtabpage.enabled" = false; # Disables the complex new tab page
      "browser.newtab.preload" = false; # No need to preload it

      # --- Hardware Acceleration (Fix for Tearing) ---
      "gfx.webrender.all" = true; # Force-enable WebRender (Firefox's GPU renderer)
      "gfx.webrender.enabled" = true; # Just to be sure
      "media.ffmpeg.vaapi.enabled" = true; # This is the main one: enables VA-API (video decoding)
      "media.ffvpx.enabled" = false; # Disables the built-in VP8/VP9 decoder to force VA-API
      "media.rdd-process.enabled" = true; # Helps with sandboxing for video decoding

      "widget.wayland.opaque-region.enabled" = false;

      # --- Auto-Enable Extensions & Hide Prompts ---
      "extensions.startupScanScopes" = 1;
      "extensions.showDomainRestrictions" = false;

      # --- Hide Bookmarks Bar ---
      "browser.toolbars.bookmarks.visibility" = "never";

      # --- Disable Welcome, Hints, and Tours ---
      "browser.startup.homepage_override.mstone" = "ignore";
      "browser.tabs.firefox-view" = false;
      "browser.tabs.firefox-view-newIcon" = false;
    };
  in {
    home.sessionVariables = {
      # Force Firefox to use Wayland
      MOZ_ENABLE_WAYLAND = "1";
      # Hardware acceleration
      MOZ_WEBRENDER = "1";
      MOZ_ACCELERATED = "1";
    };

    stylix.targets.firefox = {
      enable = true;
      profileNames = ["default"];
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
              urls = [{template = "https://search.brave.com/search?q={searchTerms}";}];
              icon = "${pkgs.brave}/share/pixmaps/brave.png";
              definedAliases = ["@brave"];
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
