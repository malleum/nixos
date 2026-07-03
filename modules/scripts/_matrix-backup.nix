{pkgs, ...}:
pkgs.writeShellScriptBin "matrix-backup" ''
  set -euo pipefail

  # Back up all Matrix (Synapse) state that is NOT reproducible from the
  # nixos config:
  #   * the Postgres database  -> messages, room state, account data
  #   * the media store        -> uploaded pictures / files (~1.6G)
  #   * the homeserver signing key (generated at runtime, 0600, not in sops)
  # The DB password / registration / livekit secrets live in sops already,
  # so they are intentionally left out.
  #
  # Output: ~/backups/<date-time>.tar.gz
  #
  # Privileged files are read via per-command sudo. The archive step runs at
  # idle CPU/IO priority so it does not disturb the live site/Matrix on this
  # small box.

  backup_dir="$HOME/backups"
  mkdir -p "$backup_dir"
  stamp="$(date +%Y-%m-%d_%H-%M-%S)"
  out="$backup_dir/$stamp.tar.gz"

  staging="$(mktemp -d)"
  trap 'rm -rf "$staging"' EXIT

  echo "==> Dumping Postgres database (matrix-synapse)"
  sudo -u postgres pg_dump matrix-synapse > "$staging/matrix-synapse.sql"

  echo "==> Archiving signing key + media store + database dump"
  sudo nice -n 19 ionice -c3 tar -czf "$out" \
    -C /var/lib/matrix-synapse homeserver.signing.key media_store \
    -C "$staging" matrix-synapse.sql

  sudo chown "$(id -un):$(id -gn)" "$out"
  chmod 600 "$out"

  echo "==> Done"
  du -h "$out"
''
