{inputs, ...}: {
  # Which neovim a host gets. The full build is nixvim with LSP servers,
  # formatters and linters -- including ltex-ls-plus, which drags in a JDK --
  # and measures 7.4 GiB of closure. mvim is plain neovim-unwrapped plus the
  # hand-written Lua config in ../../mvim: no plugins, no nixvim, no bundled
  # language tooling (servers and formatters are used when a devshell puts them
  # on PATH). That is editor tooling, so it follows the `dev` module rather than
  # the hostname.
  unify.nixos = {lib, ...}: {
    options.local.fullNvim = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use the full nixvim (LSP, linters, ltex) rather than the plugin-free mvim.";
    };
  };

  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    nixvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      module = {
        imports = [(import ../../nixvim)];
        nixpkgs.source = inputs.nixpkgs;
        version.enableNixpkgsReleaseCheck = false;
      };
      extraSpecialArgs = {inherit pkgs inputs;};
    };

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

    # -u skips ~/.config/nvim/init.lua; the config dir goes first on the
    # runtimepath so its lua/ and lsp/ directories resolve. To try edits
    # without rebuilding: nvim -u mvim/init.lua --cmd 'set rtp^=mvim'
    mvim = pkgs.symlinkJoin {
      name = "mvim";
      paths = [pkgs.neovim-unwrapped];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/nvim \
          --add-flags "-u ${../../mvim}/init.lua" \
          --add-flags "--cmd 'set rtp^=${../../mvim},${mvimTreesitter}'" \
          --suffix PATH : ${lib.makeBinPath (with pkgs; [bat fd fzf ripgrep])}
        ln -s nvim $out/bin/vi
      '';
      meta.mainProgram = "nvim";
    };
  in {
    apps.default = {
      type = "app";
      program = "${nixvim}/bin/nvim";
    };
    packages.default = nixvim;

    apps.nvim = {
      type = "app";
      program = "${nixvim}/bin/nvim";
    };
    packages.nvim = nixvim;

    apps.mvim = {
      type = "app";
      program = "${mvim}/bin/nvim";
    };
    packages.mvim = mvim;
  };
}
