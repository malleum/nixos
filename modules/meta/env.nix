# Session-wide environment. Lived in both fish.nix and zsh.nix as duplicate
# definitions; it is shell-agnostic, so it belongs to neither.
{
  flake.modules.nixos.base = {hostConfig, ...}: {
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "foot";
      BROWSER = hostConfig.user.browser;
      BROWSER2 = hostConfig.user.browser2;

      # Point tools that ship their own CA bundle at the system store, so
      # security.pki blacklists (eMudhra, CVE-2026-111943) reach them too.
      # Session-only: systemd services don't see these.
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"; # nixpkgs certifi
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"; # openssl, uv, uv-managed cpython
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt"; # requests in venvs
      PIP_CERT = "/etc/ssl/certs/ca-certificates.crt";
      AWS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt"; # awscli2/botocore
      GRPC_DEFAULT_SSL_ROOTS_FILE_PATH = "/etc/ssl/certs/ca-certificates.crt";
      NODE_OPTIONS = "--use-openssl-ca"; # node's compiled-in roots -> SSL_CERT_FILE
    };
  };
}
