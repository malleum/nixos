/*
Formatting and git hooks.

`nix fmt` formats every .nix file with alejandra. The same formatter runs as a
prek hook on commit, alongside a hook that regenerates the README file tree so
it cannot drift from the repo again.

prek is a Rust reimplementation of pre-commit that reads the same config; it is
what git-hooks.nix defaults to now.

The hook is installed into .git/hooks by entering the dev shell (`nix develop`)
or by running `nix run .#install-hooks`.
*/
{inputs, ...}: {
  imports = [inputs.git-hooks.flakeModule];

  perSystem = {
    config,
    pkgs,
    ...
  }: let
    # Rebuild the fenced tree between the README markers, matching what `ls -T`
    # shows interactively: eza with Nerd Font filetype icons.
    #
    # Two flags are load-bearing:
    #   --icons=always  -- the eza module is configured icons = "auto", which
    #                      means "only on a tty". A hook writes to a pipe, so
    #                      auto would silently drop every icon.
    #   --git-ignore    -- replaces the old `git ls-files | tree --fromfile`
    #                      plumbing. eza has no way to read a file list, so
    #                      .gitignore is what keeps result/ and caches out.
    #                      Dotfiles are excluded by eza's default (no -a),
    #                      which is why .gitignore and .sops.yaml don't appear.
    #
    # The explicit `.` matters: eza with no path argument prints nothing here.
    readmeTree = pkgs.writeShellApplication {
      name = "readme-tree";
      runtimeInputs = with pkgs; [eza gnused coreutils diffutils];
      text = ''
        readme=README.md
        begin='<!-- BEGIN TREE -->'
        end='<!-- END TREE -->'

        if ! grep -qF "$begin" "$readme" || ! grep -qF "$end" "$readme"; then
          echo "readme-tree: $readme is missing the $begin / $end markers" >&2
          exit 1
        fi

        tmp=$(mktemp)
        trap 'rm -f "$tmp"' EXIT

        {
          sed "/$begin/q" "$readme"
          echo '```'
          eza --tree --icons=always --git-ignore .
          echo '```'
          sed -n "/$end/,\$p" "$readme"
        } >"$tmp"

        if ! diff -q "$readme" "$tmp" >/dev/null; then
          cp "$tmp" "$readme"
          echo "readme-tree: regenerated the file tree in $readme — restage and commit again" >&2
          exit 1
        fi
      '';
    };
  in {
    formatter = pkgs.alejandra;

    pre-commit.settings = {
      package = pkgs.prek;

      hooks = {
        alejandra.enable = true;

        readme-tree = {
          enable = true;
          name = "readme tree";
          entry = "${readmeTree}/bin/readme-tree";
          language = "system";
          pass_filenames = false;
          always_run = true;
        };
      };
    };

    # `nix run .#install-hooks` wires prek into .git/hooks without needing to
    # keep a dev shell open.
    apps.install-hooks = {
      type = "app";
      program =
        (pkgs.writeShellScript "install-hooks" ''
          ${config.pre-commit.installationScript}
        '')
        .outPath;
    };

    devShells.default = pkgs.mkShell {
      shellHook = config.pre-commit.installationScript;
      packages = [pkgs.alejandra pkgs.prek];
    };
  };
}
