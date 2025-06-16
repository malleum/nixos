{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override {pipewireSupport = true;}) {};
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      ExtensionSettings = {
        "*" = {
          installation_mode = "allowed";
          allowed_types = ["extension"];
        };
      };
    };
  };
  home-manager.users.joshammer = {
    stylix.targets.firefox.profileNames = ["default"];
    programs.firefox = {
      enable = true;
      profiles.default = {
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            bitwarden
            darkreader
            tridactyl
            ublock-origin
          ];
        };
        settings = {
          search = {
            default = "Brave";
            engines = {
              "Brave" = {
                urls = [
                  {
                    template = "https://search.brave.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "https://brave.com/static-assets/images/brave-favicon.png";
                definedAliases = ["Brave" "brave"];
              };
            };
          };

          # Disable all popup hints and tips
          "browser.chrome.toolbar_tips" = false;
          "browser.uitour.enabled" = false;
          "browser.uitour.url" = "";

          # Disable feature callouts and hints
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.urlbar.shortcuts.quicksuggest" = false;

          # Disable new feature notifications
          "browser.messaging-system.whatsNewPanel.enabled" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;

          # Disable tooltips and callouts
          "browser.tabs.firefox-view-newIcon" = false;
          "browser.toolbars.bookmarks.visibility" = "never";

          # Disable onboarding and intro screens
          "browser.onboarding.enabled" = false;

          # Disable contextual feature recommendations (CFR)
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.getAddons.showPane" = false;

          # Disable address bar suggestions/hints
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.calculator" = false;

          # Disable What's New notifications
          # Force native Wayland mode (crucial for performance)
          "widget.use-xvfb" = false;
          "gfx.webrender.enabled" = true;

          # Wayland-specific optimizations
          "widget.dmabuf.force-enabled" = true; # Better memory sharing
          "media.hardware-video-decoding.force-enabled" = true;
          "media.rdd-vpx.enabled" = false; # Can cause issues on Wayland

          # Compositor optimizations for Hyprland
          "gfx.canvas.accelerated" = true;

          # Reduce compositing overhead
          "layout.frame_rate.precise" = true;
          "gfx.vsync.hw-vsync.enabled" = true;
          # Startup performance
          "browser.startup.preXulSkeletonUI" = false; # Skip skeleton UI delay
          "browser.aboutwelcome.enabled" = false; # Skip welcome screen

          # Reduce initial loading
          "browser.sessionstore.restore_on_demand" = true; # Don't restore all tabs immediately
          "browser.sessionstore.restore_tabs_lazily" = true;
          "extensions.webextensions.background-delayed-startup" = true;

          # Disable unnecessary services at startup
          "browser.safebrowsing.downloads.enabled" = false;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "network.prefetch-next" = false;

          # Memory/performance
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 65536; # 64MB cache

          # Disable welcome screens and first-run stuff
          "browser.startup.firstrunSkipsHomepage" = true;
          "startup.homepage_welcome_url" = "";
          "startup.homepage_welcome_url.additional" = "";
          "browser.startup.homepage_override.mstone" = "ignore";

          # Disable default browser prompts
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;

          # Auto-enable extensions
          "extensions.autoDisableScopes" = 0;
          "extensions.enabledScopes" = 15;
          "extensions.installDistroAddons" = true;
          "extensions.shownSelectionUI" = true;
          "extensions.webextensions.uuids" = "{}";
          "extensions.startupScanScopes" = 15;

          # Skip extension install confirmation dialogs
          "extensions.install_origins.enabled" = false;

          # Privacy/security (your existing ones are good)
          "privacy.trackingprotection.enabled" = true;
          "dom.security.https_only_mode" = true;
          "privacy.donottrackheader.enabled" = true;

          # Additional privacy
          "privacy.clearOnShutdown.cache" = false; # Keep cache for performance
          "privacy.clearOnShutdown.cookies" = false; # Keep login sessions
          "network.cookie.sameSite.noneRequiresSecure" = true;
          "privacy.firstparty.isolate" = false; # Can break some sites if true
          "network.http.referer.XOriginPolicy" = 2; # Only send referer to same origin

          # Performance
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true; # Hardware video acceleration on Linux
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.compositor.force-enabled" = true;

          # UI/UX improvements
          "browser.tabs.warnOnClose" = false;
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.enabled" = false; # Disable Firefox home page
          "browser.tabs.firefox-view" = false; # Disable Firefox View button
          "browser.compactmode.show" = true; # Allow compact density
          "browser.uidensity" = 1; # 0=normal, 1=compact, 2=touch

          # Downloads
          "browser.download.useDownloadDir" = true; # Never ask where to save
          "browser.download.always_ask_before_handling_new_types" = true;

          # Search/address bar
          "browser.urlbar.suggest.searches" = false; # Don't suggest search terms
          "browser.urlbar.shortcuts.bookmarks" = false;
          "browser.urlbar.shortcuts.tabs" = false;
          "browser.urlbar.shortcuts.history" = false;

          # Disable telemetry/data collection
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;

          # Media settings
          "media.eme.enabled" = true; # Enable DRM for Netflix, etc (set false if you don't want DRM)
          "media.autoplay.default" = 2; # Block autoplay audio/video (0=allow, 1=block audio, 2=block all)

          # Font rendering (especially good on Linux)
          "gfx.font_rendering.cleartype_params.rendering_mode" = 5;
          "gfx.font_rendering.cleartype_params.cleartype_level" = 100;
        };
      };
    };

    home.file.".config/tridactyl/tridactylrc".text = ''
      set configversion 2.0
      set searchengine brave
      set searchurls.brave https://search.brave.com/search?q=%s

      colourscheme dark
      guiset_quiet hoverlink right

    '';
  };
}
