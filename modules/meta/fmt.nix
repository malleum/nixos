/*
Formatting and git hooks.

`nix fmt` formats every .nix file with alejandra. The same formatter runs as a
prek hook on commit, along with stylua for the Lua in mvim/.

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
  }: {
    formatter = pkgs.alejandra;

    pre-commit.settings = {
      package = pkgs.prek;

      hooks = {
        alejandra.enable = true;
        # Lua (mvim/), styled by .stylua.toml at the repo root.
        stylua.enable = true;
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
      # Editor tooling for the repo's two languages: nix (modules, hosts) and
      # lua (mvim). Loaded by direnv via .envrc.
      packages = with pkgs; [
        alejandra
        lua-language-server
        nixd
        prek
        stylua
      ];
    };
  };
}
