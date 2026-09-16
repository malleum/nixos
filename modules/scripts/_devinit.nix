# devinit: writes a flake dev shell with the language servers and formatters a
# project's files need, plus .envrc, and loads it with direnv. Pairs with mvim,
# which bundles no language tooling.
#
# nix and direnv come from the user profile: direnv so its nix-direnv hook
# applies, nix so the system's registry pin resolves.
{pkgs}:
pkgs.writeShellApplication {
  name = "devinit";
  runtimeInputs = with pkgs; [coreutils fd git gnugrep jq];
  text = ''
    # devinit: generate a flake dev shell with the language servers and
    # formatters for the files in the current repo (or directory), wire it up to
    # direnv, and load it.
    #
    #   devinit             write flake.nix + .envrc, ignore .direnv/, direnv allow
    #   devinit --dry-run   print the flake.nix it would write and exit
    #   devinit --force     overwrite an existing flake.nix

    usage() {
      cat <<'EOF'
    usage: devinit [--dry-run] [--force]
      (no flags)     write flake.nix + .envrc, ignore .direnv/, direnv allow
      -n, --dry-run  print the flake.nix it would write and exit
      -f, --force    overwrite an existing flake.nix
    EOF
    }

    dry_run=0
    force=0
    for arg in "$@"; do
      case "$arg" in
      -n | --dry-run) dry_run=1 ;;
      -f | --force) force=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "devinit: unknown argument: $arg" >&2
        usage >&2
        exit 2
        ;;
      esac
    done

    in_repo=0
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
      in_repo=1
      cd "$root"
      list_files() { git ls-files --cached --others --exclude-standard; }
    else
      root=$PWD
      list_files() { fd --type f --hidden --exclude .git --exclude .direnv --exclude node_modules --exclude target; }
    fi

    # ── Detect languages ────────────────────────────────────────────────────────
    declare -A langs=()
    while IFS= read -r path; do
      name=''${path##*/}
      ext=""
      [[ $name == *.* ]] && ext=''${name##*.}
      ext=''${ext,,}
      case "$name" in
      go.mod | go.work) langs[go]=1 ;;
      Cargo.toml) langs[rust]=1 ;;
      esac
      case "$ext" in
      nix) langs[nix]=1 ;;
      lua) langs[lua]=1 ;;
      py) langs[python]=1 ;;
      rs) langs[rust]=1 ;;
      go) langs[go]=1 ;;
      js | mjs | cjs | jsx | ts | mts | cts | tsx) langs[typescript]=1 ;;
      json | jsonc) langs[json]=1 ;;
      html | htm) langs[html]=1 ;;
      css | scss | less) langs[css]=1 ;;
      typ) langs[typst]=1 ;;
      ex | exs | eex | heex | leex) langs[elixir]=1 ;;
      java) langs[java]=1 ;;
      zig | zon) langs[zig]=1 ;;
      c | h | cc | cpp | cxx | hpp | hh | hxx) langs[c]=1 ;;
      sql) langs[sql]=1 ;;
      sh | bash) langs[bash]=1 ;;
      yaml | yml) langs[yaml]=1 ;;
      toml) langs[toml]=1 ;;
      md | markdown) langs[markdown]=1 ;;
      esac
    done < <(list_files)

    # nixpkgs attributes per language: language server first, then formatters and
    # whatever the server needs to run. Order here is the order in flake.nix.
    order=(nix lua python rust go typescript json html css typst elixir java zig c sql bash yaml toml markdown)
    declare -A tools=(
      [nix]="nixd alejandra"
      [lua]="lua-language-server stylua"
      [python]="ty ruff isort"
      [rust]="rust-analyzer rustfmt cargo rustc"
      [go]="gopls gotools go"
      [typescript]="typescript-language-server prettierd nodejs"
      [json]="vscode-langservers-extracted"
      [html]="vscode-langservers-extracted prettierd"
      [css]="vscode-langservers-extracted prettierd"
      [typst]="tinymist typstyle"
      [elixir]="elixir-ls elixir"
      [java]="jdt-language-server"
      [zig]="zls zig"
      [c]="clang-tools"
      [sql]="sqls"
      [bash]="bash-language-server shfmt shellcheck"
      [yaml]="yaml-language-server prettierd"
      [toml]="taplo"
      [markdown]="marksman"
    )

    declare -A seen=()
    package_lines=""
    found=()
    for lang in "''${order[@]}"; do
      [[ -n ''${langs[$lang]:-} ]] || continue
      found+=("$lang")
      new=()
      for pkg in ''${tools[$lang]}; do
        [[ -n ''${seen[$pkg]:-} ]] && continue
        seen[$pkg]=1
        new+=("$pkg")
      done
      ((''${#new[@]})) || continue
      package_lines+="          # $lang"$'\n'
      for pkg in "''${new[@]}"; do
        package_lines+="          $pkg"$'\n'
      done
    done

    if ((''${#found[@]} == 0)); then
      echo "devinit: no known languages found in $root; writing an empty shell" >&2
    else
      echo "devinit: detected ''${found[*]}" >&2
    fi

    flake=$(
      cat <<EOF
    {
      description = "Development shell";

      inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

      outputs = {nixpkgs, ...}: let
        systems = ["x86_64-linux" "aarch64-linux"];
        forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.\''${system});
      in {
        devShells = forAllSystems (pkgs: {
          default = pkgs.mkShell {
            packages = with pkgs; [
    ''${package_lines}        ];
          };
        });
      };
    }
    EOF
    )

    if ((dry_run)); then
      printf '%s\n' "$flake"
      exit 0
    fi

    # ── Write files ─────────────────────────────────────────────────────────────
    if [[ -e flake.nix && $force -eq 0 ]]; then
      echo "devinit: $root/flake.nix already exists; add the shell by hand, or rerun with --force" >&2
      echo "devinit: see what it would write with --dry-run" >&2
      exit 1
    fi
    printf '%s\n' "$flake" >flake.nix
    echo "devinit: wrote flake.nix" >&2

    if [[ ! -e .envrc ]]; then
      echo "use flake" >.envrc
      echo "devinit: wrote .envrc" >&2
    elif ! grep -qx 'use flake' .envrc; then
      echo "use flake" >>.envrc
      echo "devinit: added 'use flake' to .envrc" >&2
    fi

    if ((in_repo)); then
      if [[ ! -e .gitignore ]] || ! grep -qxE '/?\.direnv/?' .gitignore; then
        # Keep the file newline-terminated before appending.
        if [[ -s .gitignore && -n $(tail -c1 .gitignore) ]]; then
          echo >>.gitignore
        fi
        echo ".direnv/" >>.gitignore
        echo "devinit: added .direnv/ to .gitignore" >&2
      fi
      # Flakes in a git repo only see tracked files.
      git add --intent-to-add flake.nix
    fi

    # Lock nixpkgs to the revision the system runs, so the tools are usually
    # already in the store. The input URL stays nixos-unstable for later updates.
    rev=$(nix flake metadata nixpkgs --json 2>/dev/null | jq -r '.locked.rev // empty' || true)
    if [[ -n $rev ]]; then
      nix flake lock --override-input nixpkgs "github:NixOS/nixpkgs/$rev"
    else
      nix flake lock
    fi
    if ((in_repo)); then
      git add --intent-to-add flake.lock
    fi

    # ── Load it ─────────────────────────────────────────────────────────────────
    if command -v direnv >/dev/null; then
      direnv allow
      echo "devinit: building the shell" >&2
      direnv exec . true
      echo "devinit: done; the shell loads on your next prompt in $root" >&2
    else
      echo "devinit: direnv not found; run 'nix develop' instead" >&2
    fi
  '';
}
