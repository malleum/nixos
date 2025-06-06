{pkgs, ...}:
pkgs.writeShellScriptBin "qb" ''
  # initial idea: Florian Bruhin (The-Compiler)
  # author: Thore Bödecker (foxxx0)

  _url="$1"
  _qb_version='1.0.4'
  _proto_version=1
  _ipc_socket="''${XDG_RUNTIME_DIR}/qutebrowser/ipc-$(printf '%s' "$USER" | md5sum | cut -d' ' -f1)"
  _qute_bin="${pkgs.qutebrowser}/bin/qutebrowser"

  printf '{"args": ["%s"], "target_arg": null, "version": "%s", "protocol_version": %d, "cwd": "%s"}\n' \
         "''${_url}" \
         "''${_qb_version}" \
         "''${_proto_version}" \
         "''${PWD}" | ${pkgs.socat}/bin/socat -lf /dev/null - UNIX-CONNECT:"''${_ipc_socket}" || "$_qute_bin" "$@" &
''
