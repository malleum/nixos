# Matrix Synapse server (minimus-only).
# Serves client and federation on 80/443 via nginx; Synapse listens on localhost:8008.
# Secrets (DB password, registration) are in sops: modules/secrets/matrix.yaml.
#
# Before first deploy:
# 1. Put your generated secrets in modules/secrets/matrix.yaml (replace placeholders).
# 2. Encrypt: sops -e -i modules/secrets/matrix.yaml
# 3. Point DNS for ws42.top and admin.ws42.top to this host; open 80, 443, UDP 3478/5349 and 49152-65535 in Oracle VCN.
#
# If Element shows "Cannot reach homeserver": from the server run
#   curl -sI https://ws42.top/_matrix/client/versions
# and check matrix-synapse + nginx (systemctl status matrix-synapse nginx; journalctl -u matrix-synapse -n 30).
let
  matrixDomain = "ws42.top";
  adminDomain = "admin.ws42.top";
  matrixSecretsFile = ./. + "/../secrets/matrix.yaml";
  # Optional: custom background for Element login/startup page.
  # Set to a store path (e.g. ./my-bg.jpg) or a URL string (e.g. "https://example.com/bg.jpg").
  # Leave null for the default Element background.
  elementWelcomeBackground = ../style/wallpapers/ws42.png;
in {
  unify.modules.matrix.nixos = {
    pkgs,
    config,
    ...
  }: let
    acmeEmail = config.user.email or "admin@ws42.top";
    # Optional welcome background: URL to use in Element config (null = no custom branding)
    welcomeBgUrl =
      if elementWelcomeBackground == null
      then null
      else if builtins.isPath elementWelcomeBackground
      then "https://${matrixDomain}/custom/welcome-bg"
      else elementWelcomeBackground;
    # Directory with custom/welcome-bg so nginx can use root (avoids alias path-traversal warning)
    welcomeBgRoot = pkgs.runCommand "element-welcome-bg-root" {} ''
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
      };
    };
  in {
    # --- Sops: Matrix secrets (DB password, registration shared secret) ---
    sops.secrets.matrix-db-password = {
      sopsFile = matrixSecretsFile;
      key = "matrix_db_password";
    };
    sops.secrets.matrix-registration-secret = {
      sopsFile = matrixSecretsFile;
      key = "matrix_registration_secret";
      restartUnits = ["matrix-synapse.service"];
    };
    sops.secrets.matrix-turn-secret = {
      sopsFile = matrixSecretsFile;
      key = "matrix_turn_secret";
      restartUnits = ["matrix-synapse.service" "coturn.service"];
      group = "turnserver";
      mode = "0440";
    };

    # Template: Synapse extra config (registration_shared_secret, database, turn_shared_secret from sops).
    # Include the full database block here so the extra file does not replace and drop "name" from the main config.
    # matrix-synapse runs as User=matrix-synapse and must be able to read this file.
    sops.templates.matrix-synapse-secrets = {
      content = ''
        registration_shared_secret: "${config.sops.placeholder.matrix-registration-secret}"
        turn_shared_secret: "${config.sops.placeholder.matrix-turn-secret}"
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
        CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD '${config.sops.placeholder.matrix-db-password}';
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
                names = ["client"];
                compress = true;
              }
              {
                names = ["federation"];
                compress = false;
              }
            ];
          }
        ];
        max_upload_size = "50M";
        max_image_pixels = "32M";
        url_preview_enabled = true;
        report_stats = false;
        presence.enabled = true;
        # Encrypted voice/video: TURN (coturn) so clients can connect for calls
        turn_uris = [
          "turn:${matrixDomain}:3478?transport=udp"
          "turn:${matrixDomain}:3478?transport=tcp"
          "turns:${matrixDomain}:5349?transport=tcp"
        ];
        # turn_shared_secret comes from extraConfigFiles (matrix-synapse-secrets template)
      };
    };

    # --- Coturn (TURN/STUN for Matrix voice/video) ---
    services.coturn = {
      enable = true;
      use-auth-secret = true;
      static-auth-secret-file = config.sops.secrets.matrix-turn-secret.path;
      realm = matrixDomain;
      no-tls = false;
      no-udp = false;
      no-tcp-relay = false;
      listening-port = 3478;
      tls-listening-port = 5349;
      min-port = 49152;
      max-port = 65535;
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
            "/.well-known/matrix/client" = {
              return = "200 '{\"m.homeserver\": {\"base_url\": \"https://${matrixDomain}\"}}'";
              extraConfig = ''
                default_type application/json;
                add_header Access-Control-Allow-Origin *;
              '';
            };
            "/.well-known/matrix/server" = {
              return = "200 '{\"m.server\": \"${matrixDomain}:443\"}'";
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
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Host $host;
                proxy_connect_timeout 10s;
                proxy_read_timeout 60s;
              '';
            };
            "/_synapse/client/" = {
              proxyPass = "http://127.0.0.1:8008";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Host $host;
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

        root = pkgs.synapse-admin;

        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
        };
        locations."/_matrix/" = {
          proxyPass = "http://127.0.0.1:8008";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
          '';
        };
        locations."/_synapse/" = {
          proxyPass = "http://127.0.0.1:8008";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
          '';
        };
      };
    };

    # --- Firewall: HTTP/HTTPS and TURN (UDP 3478, 5349, relay range) ---
    networking.firewall = {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [3478 5349];
      allowedUDPPortRanges = [
        {
          from = 49152;
          to = 65535;
        }
      ];
    };
  };
}
