{
  # The neovim build. mvim is plain neovim-unwrapped plus the hand-written Lua
  # config in ../../mvim: no plugins, no bundled language tooling (servers and
  # formatters are used when a devshell puts them on PATH). Every host gets it
  # as `nvim` and `vi` (modules/packages/cli.nix).
  #
  # It is the only editor build here. The nixvim configuration that used to sit
  # alongside it -- LSP servers, formatters, linters and a 7.4 GiB closure --
  # is gone, along with its flake input and the `local.fullNvim` switch.
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    # Treesitter for mvim: neovim bundles c, lua, markdown, query, vim and
    # vimdoc; these add the languages in regular use. Highlight queries come
    # from nvim-treesitter (as data -- the plugin itself is not loaded), and
    # the query-only entries are ones the others inherit from.
    mvimTreesitter = let
      ts = pkgs.vimPlugins.nvim-treesitter;
      grammars = [
        "bash"
        "comment"
        "cpp"
        "css"
        "diff"
        "dockerfile"
        "eex"
        "elixir"
        "gitcommit"
        "git_rebase"
        "go"
        "gomod"
        "gosum"
        "gowork"
        "heex"
        "html"
        "java"
        "javascript"
        "jsdoc"
        "json"
        "make"
        "nix"
        "printf"
        "python"
        "regex"
        "rust"
        "sql"
        "toml"
        "tsx"
        "typescript"
        "typst"
        "yaml"
        "zig"
      ];
      queryOnly = ["ecma" "html_tags" "jsx"];
    in
      pkgs.linkFarm "mvim-treesitter" (
        map (lang: {
          name = "parser/${lang}.so";
          path = "${ts.grammarPlugins.${lang}}/parser/${lang}.so";
        })
        grammars
        ++ map (lang: {
          name = "queries/${lang}";
          path = "${ts}/runtime/queries/${lang}";
        }) (grammars ++ queryOnly)
      );

    # The mvim/ directory with its help tags generated, so `:help mvim` works.
    # Named "mvim" so running panes still show ".../mvim/init.lua", which is
    # how tmux-resurrect recognizes them (modules/programs/tmux.nix).
    mvimConfig = pkgs.runCommand "mvim" {} ''
      cp -r ${../../mvim} $out
      chmod -R u+w $out
      rm -rf $out/tests
      ${pkgs.neovim-unwrapped}/bin/nvim --headless --clean -c "helptags $out/doc" -c q
    '';

    # -u skips ~/.config/nvim/init.lua; the config dir goes first on the
    # runtimepath so its lua/, lsp/ and doc/ directories resolve. To try edits
    # without rebuilding: nvim -u mvim/init.lua --cmd 'set rtp^=mvim'
    mvim = pkgs.symlinkJoin {
      name = "mvim";
      paths = [pkgs.neovim-unwrapped];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/nvim \
          --add-flags "-u ${mvimConfig}/init.lua" \
          --add-flags "--cmd 'set rtp^=${mvimConfig},${mvimTreesitter}'" \
          --suffix PATH : ${lib.makeBinPath (with pkgs; [bat fd fzf ripgrep])}
        ln -s nvim $out/bin/vi
      '';
      meta.mainProgram = "nvim";
    };

    # mvim's test suite (mvim/tests): drives a real mvim over RPC, about 3 s.
    mvimTest = pkgs.writeShellScript "mvim-test" ''
      MVIM=${mvim}/bin/nvim exec ${pkgs.neovim-unwrapped}/bin/nvim --clean -l ${../../mvim/tests}/run.lua "$@"
    '';
  in {
    checks.mvim = pkgs.runCommand "mvim-tests" {nativeBuildInputs = with pkgs; [direnv git];} ''
      export HOME=$TMPDIR
      ${mvimTest}
      touch $out
    '';

    # `nix run .#mvim-test -- [filter]`
    apps.mvim-test = {
      type = "app";
      program = "${mvimTest}";
    };

    apps.default = {
      type = "app";
      program = "${mvim}/bin/nvim";
    };
    packages.default = mvim;

    apps.mvim = {
      type = "app";
      program = "${mvim}/bin/nvim";
    };
    packages.mvim = mvim;
  };
}
