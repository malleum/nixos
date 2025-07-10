{pkgs, ...}: let
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
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
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

      lualine = {
        enable = true;
        settings = {
          options = {
            section_separators = {
              left = "";
              right = "";
            };
            component_separators = {
              left = "\\";
              right = "/";
            };
          };
          sections = {
            lualine_a = ["mode"];
            lualine_b = ["branch" "diff" "diagnostics"];
            lualine_c = ["filename"];
            lualine_x = ["selectioncount" "filetype"];
            lualine_y = ["encoding" "filexxformat"];
            lualine_z = ["location"];
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
