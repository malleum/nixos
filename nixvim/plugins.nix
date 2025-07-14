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
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [bash c gdscript cmake cpp c-sharp css dockerfile go gomod gosum gowork html java javascript jq json json5 jsonc kotlin lua markdown nix ocaml php python query ruby rust scala scss sql svelte toml typescript vim yaml zig];
        settings = {highlight.enable = true;};
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
        # Define colors from your Stylix palette
        colors = {
          bg = "#${config.stylix.base16Scheme.base00}";
          bg_alt = "#${config.stylix.base16Scheme.base01}";
          fg = "#${config.stylix.base16Scheme.base05}";
          fg_dark = "#${config.stylix.base16Scheme.base03}";

          red = "#${config.stylix.base16Scheme.base08}";
          green = "#${config.stylix.base16Scheme.base0B}";
          blue = "#${config.stylix.base16Scheme.base0D}";
          yellow = "#${config.stylix.base16Scheme.base0A}";
          magenta = "#${config.stylix.base16Scheme.base0E}";
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
      (pkgs.vimUtils.buildVimPlugin {
        name = "grapplevim";
        src = ./grapplevim;
      })
    ];
    extraConfigLua =
      # lua
      ''
        require('grapplevim').setup({map_leader = "<Backspace>"})

        vim.api.nvim_create_autocmd('BufWinEnter', {
          pattern = '*',
          callback = function()
            if vim.bo.filetype == 'gdscript' and vim.wo.previewwindow then
              vim.treesitter.start()
            end
          end,
        })

        vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
          pattern = '*.gd',
          command = 'set filetype=gdscript',
        })
      '';
  };
}
