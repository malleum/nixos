# Matrix Synapse server (minimus-only).
# Serves client and federation on 80/443 via nginx; Synapse listens on localhost:8008.
# Secrets (DB password, registration, livekit key) are in sops: modules/secrets/matrix.yaml.
#
# Before first deploy:
# 1. Put your generated secrets in modules/secrets/matrix.yaml (replace placeholders).
# 2. Encrypt: sops -e -i modules/secrets/matrix.yaml
# 3. Point DNS for ws42.top and admin.ws42.top to this host; open 80, 443, 5349/tcp, 3478/udp, UDP 50000-51000 in Oracle VCN.
#
# If Element shows "Cannot reach homeserver": from the server run
#   curl -sI https://ws42.top/_matrix/client/versions
# and check matrix-synapse + nginx (systemctl status matrix-synapse nginx; journalctl -u matrix-synapse -n 30).
let
  matrixDomain = "ws42.top";
  adminDomain = "admin.ws42.top";
  matrixSecretsFile = ../secrets/matrix.yaml;
  # Optional: custom background for Element login/startup page.
  # Set to a store path (e.g. ./my-bg.jpg) or a URL string (e.g. "https://example.com/bg.jpg").
  # Leave null for the default Element background.
  elementWelcomeBackground = ../style/wallpapers/ws42.png;
in {
  unify.modules.matrix.nixos = {
    pkgs,
    hostConfig,
    config,
    ...
  }: let
    acmeEmail = hostConfig.user.email;
    # Optional welcome background: URL to use in Element config (null = no custom branding)
    welcomeBgUrl =
      if elementWelcomeBackground == null
      then null
      else if builtins.isPath elementWelcomeBackground
      then "https://${matrixDomain}/custom/welcome-bg"
      else elementWelcomeBackground;
    # Directory with custom/welcome-bg so nginx can use root (avoids alias path-traversal warning)
    welcomeBgRoot = pkgs.runCommandLocal "element-welcome-bg-root" {} ''
      mkdir -p $out/custom
      cp ${elementWelcomeBackground} $out/custom/welcome-bg
    '';
    # Element Web with ws42.top as default homeserver (login/signup pre-configured)
    elementWeb = pkgs.element-web.override {
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://${matrixDomain}";
            server_name = matrixDomain;
          };
        };
        default_theme = "dark";
        # On mobile: stay on the web app for sign-up/login instead of prompting to download the app
        mobile_guide_toast = false;
        # When they do choose "Get the app", recommend Element Classic (not Element X)
        mobile_guide_app_variant = "element-classic";
        mobile_builds = {
          ios = "https://apps.apple.com/app/element-messenger/id1083446067";
          android = "https://play.google.com/store/apps/details?id=im.vector.app";
          fdroid = "https://f-droid.org/en/packages/im.vector.app/";
        };
        branding = pkgs.lib.optionalAttrs (welcomeBgUrl != null) {
          welcome_background_url = welcomeBgUrl;
        };
        # Element Call: use LiveKit-backed calls instead of Jitsi
        element_call = {
          url = "https://call.element.io";
          use_exclusively = true;
          brand = "Element Call";
        };
        features = {
          feature_group_calls = true;
          feature_video_rooms = true;
          feature_element_call_video_rooms = true;
        };
      };
    };

    # Synapse Admin with ws42.top as default homeserver (using the main domain for API)
    synapseAdmin = pkgs.runCommandLocal "synapse-admin-configured" {} ''
      cp -r ${pkgs.synapse-admin} $out
      chmod -R +w $out
      echo '{"restrictBaseUrl": "https://${adminDomain}"}' > $out/config.json
    '';
  in {
    # --- Sops: Matrix secrets (DB password, registration shared secret, LiveKit key) ---
    sops.secrets.matrix-db-password = {
      sopsFile = matrixSecretsFile;
      key = "matrix_db_password";
    };
    sops.secrets.matrix-registration-secret = {
      sopsFile = matrixSecretsFile;
      key = "matrix_registration_secret";
      restartUnits = ["matrix-synapse.service"];
    };
    sops.secrets.matrix-livekit-key = {
      sopsFile = matrixSecretsFile;
      key = "matrix_livekit_key";
      restartUnits = ["livekit.service" "lk-jwt-service.service"];
    };

    # Template: Synapse extra config (registration_shared_secret, database).
    sops.templates.matrix-synapse-secrets = {
      content = ''
        registration_shared_secret: "${config.sops.placeholder.matrix-registration-secret}"
        database:
          name: psycopg2
          args:
            user: matrix-synapse
            database: matrix-synapse
            host: localhost
            password: "${config.sops.placeholder.matrix-db-password}"
      '';
      path = "/run/secrets/matrix-synapse-extra.yaml";
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0440";
    };

    # Template: PostgreSQL init script (DB password from sops)
    sops.templates.matrix-db-init = {
      content = ''
        CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD $sops$${config.sops.placeholder.matrix-db-password}$sops$;
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
      '';
      path = "/run/secrets/matrix-db-init.sql";
      owner = "postgres";
      group = "postgres";
      mode = "0440";
    };

    # --- PostgreSQL for Synapse ---
    services.postgresql = {
      enable = true;
      initialScript = config.sops.templates.matrix-db-init.path;
    };
    # Ensure sops renders the DB init script before PostgreSQL first starts
    systemd.services.postgresql.after = ["sops-nix.service"];
    systemd.services.postgresql.wants = ["sops-nix.service"];

    # --- Synapse ---
    services.matrix-synapse = {
      enable = true;
      extraConfigFiles = [config.sops.templates.matrix-synapse-secrets.path];
      settings = {
        server_name = matrixDomain;
        public_baseurl = "https://${matrixDomain}/";
        enable_registration = true;
        # Newer Element mobile: sign up only with a registration token (create via admin API / register_new_matrix_user -c).
        registration_requires_token = true;
        # Federation disabled: do not send or accept federation.
        federation_domain_whitelist = [];
        # database (name, args with password) is in extraConfigFiles (matrix-synapse-secrets) so the secret is not in the Nix store.
        listeners = [
          {
            port = 8008;
            bind_addresses = ["127.0.0.1" "::1"];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = ["client" "federation"];
                compress = true;
              }
            ];
          }
        ];
        max_upload_size = "50M";
        max_image_pixels = "32M";
        url_preview_enabled = true;
        report_stats = false;
        presence.enabled = true;

        # Experimental features (needed for Element Call / MatrixRTC)
        experimental_features = {
          msc3266_enabled = true; # Room summary API
          msc4222_enabled = true; # SyncV2 state_after (reliable call state tracking)
        };

        # MSC4140: delayed events for call participation signalling (prevents stuck calls)
        max_event_delay_duration = "24h";

        # Rate limits tuned for call heartbeats / E2EE key sharing
        rc_message = {
          per_second = 0.5;
          burst_count = 30;
        };
        rc_delayed_event_mgmt = {
          per_second = 1;
          burst_count = 20;
        };
      };
    };

    # --- LiveKit (SFU for Matrix voice/video via Element Call) ---
    # Shared group so both nginx and livekit can read the ACME TLS certs (needed for TURN TLS)
    users.groups.acme-ws42 = {};
    security.acme.certs.${matrixDomain} = {
      group = "acme-ws42";
      # Restart livekit when certs renew so it picks up the new files
      reloadServices = ["livekit.service"];
    };
    users.users.nginx.extraGroups = ["acme-ws42"];
    systemd.services.livekit.serviceConfig.SupplementaryGroups = ["acme-ws42"];

    services.livekit = {
      enable = true;
      keyFile = config.sops.secrets.matrix-livekit-key.path;
      config = {
        port = 7880;
        rtc = {
          port_range_start = 50000;
          port_range_end = 51000;
          # STUN discovers external IP and creates NAT mapping (158.101.121.4/10.0.0.221)
          # so LiveKit binds to the internal IP but advertises the external one.
          # This mapping is needed for TURN relay to work on Oracle Cloud NAT.
          use_external_ip = true;
          node_ip = "158.101.121.4";
        };
        turn = {
          enabled = true;
          domain = matrixDomain;
          udp_port = 3478;
          tls_port = 5349;
          # TURN relay range must match firewall — default is 1024-30000 which is blocked
          relay_range_start = 50000;
          relay_range_end = 51000;
          cert_file = "/var/lib/acme/${matrixDomain}/fullchain.pem";
          key_file = "/var/lib/acme/${matrixDomain}/key.pem";
        };
      };
    };

    # --- LiveKit JWT Service ---
    services.lk-jwt-service = {
      enable = true;
      keyFile = config.sops.secrets.matrix-livekit-key.path;
      livekitUrl = "wss://${matrixDomain}/_livekit/";
      port = 8080;
    };

    # --- TLS with ACME (Let's Encrypt); use your userconfig email ---
    security.acme = {
      acceptTerms = true;
      defaults.email = acmeEmail;
    };

    # --- Nginx: 80 and 443 (Matrix client + federation) ---
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts.${matrixDomain} = {
        forceSSL = true;
        enableACME = true;

        # Element Web at / – login/signup with homeserver already set to ws42.top
        root = elementWeb;
        # SPA: serve index.html for client-side routes (e.g. /login, /register)
        locations =
          {
            "/" = {
              tryFiles = "$uri $uri/ /index.html";
            };
            "/.well-known/matrix/server" = {
              return = "200 '{\"m.server\": \"${matrixDomain}:443\"}'";
              extraConfig = ''
                default_type application/json;
                add_header Access-Control-Allow-Origin *;
              '';
            };
            "/.well-known/matrix/client" = {
              return = "200 '{\"m.homeserver\": {\"base_url\": \"https://${matrixDomain}\"}, \"org.matrix.msc4143.rtc_foci\": [{\"type\": \"livekit\", \"livekit_service_url\": \"https://${matrixDomain}/_lk-jwt/\"}]}'";
              extraConfig = ''
                default_type application/json;
                add_header Access-Control-Allow-Origin *;
              '';
            };
            # Element Classic (and some clients) open this URL for sign-up; Synapse no longer serves it.
            # Redirect straight to Element Web sign-up so users land on the form (smooth for non-tech users).
            "/_matrix/static/client/register" = {
              return = "302 https://${matrixDomain}/#/register";
              extraConfig = "add_header Cache-Control \"no-store\";";
            };
            "/_matrix/static/client/register/" = {
              return = "302 https://${matrixDomain}/#/register";
              extraConfig = "add_header Cache-Control \"no-store\";";
            };
            "/_matrix/" = {
              proxyPass = "http://127.0.0.1:8008";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_connect_timeout 10s;
                proxy_read_timeout 60s;
              '';
            };
            "/_synapse/client/" = {
              proxyPass = "http://127.0.0.1:8008";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_connect_timeout 10s;
                proxy_read_timeout 60s;
              '';
            };
            "/_synapse/admin/" = {
              proxyPass = "http://127.0.0.1:8008";
              proxyWebsockets = true;
              extraConfig = ''
                allow 127.0.0.1;
                allow ::1;
                deny all;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Host $host;
                proxy_connect_timeout 10s;
                proxy_read_timeout 60s;
              '';
            };
            # LiveKit proxy (websocket support via proxyWebsockets)
            "/_livekit/" = {
              proxyPass = "http://127.0.0.1:7880/";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_connect_timeout 10s;
                proxy_read_timeout 86400s;
              '';
            };
            # lk-jwt-service proxy
            "/_lk-jwt/" = {
              proxyPass = "http://127.0.0.1:8080/";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_connect_timeout 10s;
                proxy_read_timeout 60s;
              '';
            };
          }
          // (pkgs.lib.optionalAttrs (builtins.isPath elementWelcomeBackground) {
            "/custom/" = {
              root = welcomeBgRoot;
              extraConfig = "default_type image/png;";
            };
          });
      };

      # --- Synapse Admin UI at admin.ws42.top ---
      virtualHosts.${adminDomain} = {
        forceSSL = true;
        enableACME = true;

        root = synapseAdmin;

        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
        };
        locations."/_matrix/" = {
          proxyPass = "http://127.0.0.1:8008";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host ${matrixDomain};
            proxy_connect_timeout 10s;
            proxy_read_timeout 60s;
          '';
        };
        locations."/_synapse/" = {
          proxyPass = "http://127.0.0.1:8008";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host ${matrixDomain};
            proxy_connect_timeout 10s;
            proxy_read_timeout 60s;
          '';
        };
      };
    };

    # Push rules for call suppression already applied to all current users.
    # To apply for new users, log in as @admin:ws42.top via Element and use
    # the admin API manually. No persistent admin token stored.

    # --- Firewall: HTTP/HTTPS and LiveKit (UDP 50000-51000) ---
    networking.firewall = {
      allowedTCPPorts = [80 443 3478 5349 7881];
      allowedUDPPortRanges = [
        {
          from = 3478;
          to = 3478;
        }
        {
          from = 50000;
          to = 51000;
        }
      ];
    };
  };
}
