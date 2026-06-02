# Cache client. Pushes a fixed set of locally-built store paths to the
# minimus binary cache (https://malleum.us/) after each system switch.
#
# Add `cch` to a host's module list to enable.
#
# One-time setup:
# 1. On any machine: generate signing keypair
#    nix key generate-secret --key-name malleum.us-1 > cache_priv
#    nix key convert-secret-to-public < cache_priv > cache_pub
# 2. Generate SSH key for the uploader
#    ssh-keygen -t ed25519 -N "" -f cch_ssh -C cch-uploader
# 3. Encrypt the two private keys into modules/secrets/default.yaml:
#      cch_signing_key: <contents of cache_priv>
#      cch_ssh_private: <contents of cch_ssh>
#    (sops -e -i modules/secrets/default.yaml after pasting plaintext)
# 4. Paste the corresponding pubkeys into the constants below
#    (cachePubKey) and in modules/services/cache_server.nix (cchSshPubKey).
# 5. Deploy minimus first (`cache-server` module), then the laptops.
{
  unify.modules.cch.nixos = {
    pkgs,
    lib,
    ...
  }: let
    cacheUrl = "https://malleum.us/";

    # PUBLIC key from `nix key convert-secret-to-public`. Looks like
    # "malleum.us-1:BASE64...=" — replace before first deploy.
    cachePubKey = "malleum.us-1:4ce0py8ufcJUw5plVb/fpmxrLrPQFSiNyPMGMcaYBRc=";

    sshKeyPath = "/etc/ssh/cch_key";

    # Packages we expect to be rebuilt locally. Listed by their derivation
    # name (the part after the store hash). Edit this list as your set of
    # source-built pkgs changes.
    targetNames = [
      "jay"
      "iamb"
      "element-desktop"
      "element-web"
      "wl-tray-bridge"
      "nixvim"
    ];
    nameAlternation = lib.concatStringsSep "|" targetNames;
    # Match /nix/store/<32-char-hash>-<name>(-version|EOL)
    pathRegex = "/[a-z0-9]{32}-(${nameAlternation})(-|\$)";

    pushScript = pkgs.writeShellApplication {
      name = "cch-push";
      runtimeInputs = with pkgs; [nix openssh coreutils gnugrep gnused];
      text = ''
        set -eu
        sys=/run/current-system
        regex='${pathRegex}'

        # Resolve target paths from the current system closure.
        paths=$(nix-store -qR "$sys" | grep -E "$regex" | sort -u || true)
        if [ -z "$paths" ]; then
          echo "cch-push: no target paths in current system closure"
          exit 0
        fi

        count=$(echo "$paths" | wc -l)
        echo "cch-push: pushing $count paths to ${cacheUrl}"

        # nix-uploader is in trusted-users on minimus, so unsigned upload OK.
        # shellcheck disable=SC2086
        echo "$paths" | xargs nix copy --to "ssh-ng://malleum.us"

        # Register one gcroot per target name. /var/lib/laptop-cache is
        # symlinked under /nix/var/nix/gcroots on the server, so each symlink
        # here is a real GC root. Overwriting a symlink de-roots the prior
        # path; the server's weekly nh-clean then purges it. (GC itself needs
        # root, which nix-uploader is not — so we don't run it here.)
        {
          echo 'set -eu'
          for p in $paths; do
            base=$(basename "$p")
            # strip leading "<hash>-"
            name=$(echo "$base" | sed -E 's/^[a-z0-9]+-//')
            # strip trailing "-<version>" (first digit after a dash)
            name=$(echo "$name" | sed -E 's/-[0-9].*$//')
            printf 'ln -sfn %q /var/lib/laptop-cache/%s\n' "$p" "$name"
          done
        } | ssh malleum.us bash
      '';
    };
  in {
    nix.settings = {
      substituters = [cacheUrl];
      trusted-public-keys = [cachePubKey];
    };

    # System-level SSH client config so root can `ssh malleum.us` as nix-uploader.
    programs.ssh.extraConfig = ''
      Host malleum.us
        User nix-uploader
        IdentityFile ${sshKeyPath}
        StrictHostKeyChecking accept-new
    '';

    sops.secrets.cch-ssh-key = {
      key = "cch_ssh_private";
      path = sshKeyPath;
      mode = "0400";
      owner = "root";
    };

    systemd.services.cch-push = {
      description = "Push selected store paths to malleum.us binary cache";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pushScript}/bin/cch-push";
        # Keep journal output but don't block switch on completion.
      };
    };

    # Fire push asynchronously after each system switch. --no-block returns
    # immediately so activation isn't slowed by network or remote GC.
    system.activationScripts.cch-push = lib.stringAfter ["users"] ''
      ${pkgs.systemd}/bin/systemctl --no-block start cch-push.service || true
    '';
  };
}
