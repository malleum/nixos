{pkgs, ...}:
pkgs.writeShellScriptBin "pyenv" ''
  ppkgs=()
  for el in "$@"; do
    ppkgs+=("python3Packages.$el")
  done
  nix-shell -p "''${ppkgs[@]}"
''
