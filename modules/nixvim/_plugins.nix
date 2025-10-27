{
  pkgs,
  config,
  ...
}: let
  alejandra = "${pkgs.alejandra}/bin/alejandra";
  cljfmt = "${pkgs.cljfmt}/bin/cljfmt";
  gdformat = "${pkgs.gdtoolkit_4}/bin/gdformat";
  gofmt = "${pkgs.go}/bin/gofmt";
  goimports = "${pkgs.goimports-reviser}/bin/goimports-reviser";
  isort = "${pkgs.isort}/bin/isort";
  prettierd = "${pkgs.prettierd}/bin/prettierd";
  ruff = "${pkgs.ruff}/bin/ruff";
  stylua = "${pkgs.stylua}/bin/stylua";
in {
  programs.nixvim = {
    plugins = {
      oil.enable = true;
      neogit.enable = true;
      comment.enable = true;
      diffview.enable = true;
      gitsigns.enable = true;
      nvim-autopairs.enable = true;
      nvim-surround.enable = true;
      todo-comments.enable = true;
      typst-preview.enable = true;
      web-devicons.enable = true;

      treesitter = {
        enable = true;
        settings.highlight.enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [bash gdscript cmake c-sharp css dockerfile go gomod gosum gowork html java javascript jq json json5 jsonc kotlin lua markdown nix ocaml php python query ruby rust scala scss svelte toml typst typescript vim yaml zig];
      };

      conform-nvim = {
        enable = true;
        settings = {
          formatters = {
            alejandra.command = alejandra;
            cljfmt.command = cljfmt;
            gdformat.command = gdformat;
            gofmt.command = gofmt;
            goimports.command = goimports;
            isort.command = isort;
            prettierd.command = prettierd;
            ruff_format = {
              command = ruff;
              prepend_args = ["format"];
            };
            stylua.command = stylua;
          };
          formatters_by_ft = {
            "*" = ["trim_whitespace"];
            clojure = ["cljfmt"];
            gdscript = ["gdformat"];
            go = ["goimports" "gofmt"];
            javascript = ["prettierd"];
            lua = ["stylua"];
            nix = ["alejandra"];
            python = ["isort" "ruff_format"];
          };
        };
      };

      lint = {
        enable = true;
        linters.ruff.cmd = ruff;
        lintersByFt.python = ["ruff"];
      };
      lualine = let
        getColorOrDefault = baseKey: defaultHex:
          if config ? stylix && config.stylix ? base16Scheme && config.stylix.base16Scheme ? ${baseKey}
          then "#${config.stylix.base16Scheme.${baseKey}}"
          else "#${defaultHex}";
        colors = {
          bg = getColorOrDefault "base00" "12151a";
          bg_alt = getColorOrDefault "base01" "21262e";
          fg = getColorOrDefault "base05" "c5cbd3";
          fg_dark = getColorOrDefault "base03" "6c7a8b";

          red = getColorOrDefault "base08" "d18da4";
          green = getColorOrDefault "base0B" "74b3c4";
          blue = getColorOrDefault "base0D" "5e9de5";
          yellow = getColorOrDefault "base0A" "82a4b0";
          magenta = getColorOrDefault "base0E" "a396c4";
        };
      in {
        enable = true;
        settings = {
          options = {
            theme = {
              normal = {
                a = {
                  fg = colors.bg;
                  bg = colors.blue;
                  gui = "bold";
                };
                b = {
                  fg = colors.fg;
                  bg = colors.bg_alt;
                };
                c = {
                  fg = colors.fg;
                  bg = colors.bg;
                };
              };
              insert = {
                a = {
                  fg = colors.bg;
                  bg = colors.green;
                  gui = "bold";
                };
              };
              visual = {
                a = {
                  fg = colors.bg;
                  bg = colors.magenta;
                  gui = "bold";
                };
              };
              replace = {
                a = {
                  fg = colors.bg;
                  bg = colors.red;
                  gui = "bold";
                };
              };
              command = {
                a = {
                  fg = colors.bg;
                  bg = colors.yellow;
                  gui = "bold";
                };
              };
              inactive = {
                a = {
                  fg = colors.fg;
                  bg = colors.bg;
                  gui = "bold";
                };
                b = {
                  fg = colors.fg_dark;
                  bg = colors.bg;
                };
                c = {
                  fg = colors.fg_dark;
                  bg = colors.bg;
                };
              };
            };
            section_separators = {
              left = "";
              right = "";
            };
            component_separators = {
              left = "";
              right = "";
            };
            always_divide_middle = true;
          };

          sections = {
            lualine_a = ["mode"];
            lualine_b = ["branch" "diff"];
            lualine_c = ["diagnostics"];
            lualine_x = ["filetype"];
            lualine_y = ["progress"];
            lualine_z = ["location"];
          };

          # CORRECTED: Use an empty list `[]` for empty sections, not `{}`.
          inactive_sections = {
            lualine_a = [];
            lualine_b = [];
            lualine_c = ["filename"];
            lualine_x = ["location"];
            lualine_y = [];
            lualine_z = [];
          };
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>g";
        action = "<cmd>Neogit<cr>";
      }
      {
        mode = "n";
        key = "<leader>ut";
        action = "<cmd>UndotreeToggle<cr>";
      }
    ];

    extraPlugins = with pkgs.vimPlugins; [
      vim-visual-multi
      vim-indent-object
    ];
  };
}
