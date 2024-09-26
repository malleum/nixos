{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [inputs.nxvim.nixosModules.nixvim];
  stylix.targets.nixvim.enable = false;

  programs.nixvim = let
    ruff = "${pkgs.ruff}/bin/ruff";
    stylua = "${pkgs.stylua}/bin/stylua";
    alejandra = "${pkgs.alejandra}/bin/alejandra";
    isort = "${pkgs.isort}/bin/isort";
  in {
    enable = false;
    plugins = {
      ccc.enable = true;
      oil.enable = true;
      neogit.enable = true;
      comment.enable = true;
      diffview.enable = true;
      gitsigns.enable = true;
      nvim-surround.enable = true;
      undotree.enable = true;
      quickmath.enable = true;
      todo-comments.enable = true;
      nvim-autopairs.enable = true;
      markdown-preview.enable = true;
      vimtex.enable = true;
      web-devicons.enable = true;

      treesitter = {
        enable = true;
        settings = {
          auto_install = true;
          highlight.enable = true;
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          formatters = {
            ruff_format = {
              command = ruff;
              prepend_args = ["format"];
            };
            stylua.command = stylua;
            alejandra.command = alejandra;
            isort.command = isort;
          };
          formatters_by_ft = {
            lua = ["stylua"];
            nix = ["alejandra"];
            python = ["isort" "ruff_format"];
            "*" = ["trim_whitespace"];
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

      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        settings.defaults.layout_config.horizontal = {
          prompt_position = "top";
          width = 0.95;
          height = 0.85;
        };
        keymaps = {
          "<leader>h" = "find_files";
          "<leader>pg" = "git_files";
          "<leader>ps" = "live_grep";
          "<leader>pr" = "lsp_references";
          "<leader>pd" = "diagnostics";
          "<leader>ph" = "help_tags";
        };
      };

      harpoon = {
        enable = true;
        menu = {
          width = 100;
          height = 6;
        };
        keymaps = {
          addFile = "<leader>a";
          toggleQuickMenu = "<leader>o";
          navFile = {
            "1" = "<C-A-h>";
            "2" = "<C-A-t>";
            "3" = "<C-A-n>";
            "4" = "<C-A-s>";
          };
        };
      };

      flash = {
        enable = true;
        settings = {
          label.rainbow.enabled = true;
          modes = {
            search.enabled = false;
            char.enabled = false;
          };
        };
      };

      fidget.enable = true;
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          cssls.enable = true;
          clangd.enable = true;
          dartls.enable = true;
          gleam.enable = true;
          gopls.enable = true;
          html.enable = true;
          htmx.enable = true;
          java-language-server.enable = true;
          jsonls.enable = true;
          ltex.enable = true;
          lua-ls.enable = true;
          kotlin-language-server.enable = true;
          marksman.enable = true;
          nil-ls.enable = true;
          nixd.enable = true;
          ocamllsp.enable = true;
          pyright.enable = true;
          sqls.enable = true;
          rust-analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
          ts-ls.enable = true;
          zls.enable = true;
        };
        inlayHints = true;
        keymaps = {
          diagnostic = {
            "[d" = "goto_prev";
            "]d" = "goto_next";
            "gl" = "open_float";
          };
          lspBuf = {
            "K" = "hover";
            "gd" = "definition";
            "gD" = "declaration";
            "gi" = "implementation";
            "go" = "type_definition";
            "gr" = "references";
            "gs" = "signature_help";

            "<leader>rn" = "rename";
            "<leader>ra" = "code_action";
            "<leader>rr" = "references";
          };
        };
        onAttach = ''vim.keymap.set("n", "<leader>f", function() require("conform").format({ async = true, lsp_fallback = true }) end) '';
      };
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
        fromVscode = [
          {
            lazyLoad = true;
            paths = "${pkgs.vimPlugins.friendly-snippets}";
          }
        ];
      };
      cmp-nvim-lsp.enable = true; # lsp
      cmp-calc.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true; # file system paths
      cmp_luasnip.enable = true; # snippets
      cmp-cmdline.enable = true; # autocomplete for cmdlinep
      lspkind = {
        enable = true;
        extraOptions = {
          maxwidth = 50;
          ellipsis_char = "...";
        };
      };
      cmp = {
        enable = true;
        settings = {
          autoEnableSources = true;
          snippet.expand = "luasnip";
          experimental.ghost_text = true;
          preselect = "cmp.PreselectMode.Item";
          formatting.fields = ["kind" "abbr" "menu"];

          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "nvim_lua";}
            {name = "calc";}
            {name = "path";}
            {name = "buffer";}
          ];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<C-p>" = "cmp.mapping(function() if cmp.visible() then cmp.select_prev_item({behavior = 'select'}) else cmp.complete() end end)";
            "<C-n>" = "cmp.mapping(function() if cmp.visible() then cmp.select_next_item({behavior = 'select'}) else cmp.complete() end end)";
          };
          window = {
            completion = {
              border = "rounded";
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None";
            };
            documentation.border = "rounded";
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
      {
        mode = ["n"];
        key = "<leader>pt";
        action = "<cmd>TodoTelescope<cr>";
      }
      {
        mode = ["n"];
        key = "<leader>pS";
        action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input({ prompt = ' > ' }) })<cr>";
      }
      {
        mode = ["n"];
        key = "<leader>pw";
        action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<cr>";
      }
      {
        mode = ["n"];
        key = "<leader>pW";
        action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') })<cr>";
      }
      {
        mode = ["n" "x" "o"];
        key = "s";
        action = "<cmd>lua require('flash').jump()<cr>";
      }
      {
        mode = ["n" "x" "o"];
        key = "S";
        action = "<cmd>lua require('flash').treesitter()<cr>";
      }
      {
        mode = ["o"];
        key = "r";
        action = "<cmd>lua require('flash').remote()<cr>";
      }
      {
        mode = ["x" "o"];
        key = "R";
        action = "<cmd>lua require('flash').treesitter_search()<cr>";
      }
      {
        mode = ["n"];
        key = "<Space>";
        action = "<Nop>";
        options.silent = true;
      }
      {
        mode = ["n"];
        key = "<S-cr>";
        action = "<Nop>";
        options.silent = true;
      }

      {
        mode = ["n" "v"];
        key = "<leader>Y";
        action = "\"+y$";
      }
      {
        mode = ["n" "v"];
        key = "<leader>y";
        action = "\"+y";
      }
      {
        mode = ["n" "v"];
        key = "<leader>D";
        action = "\"_D";
      }
      {
        mode = ["n" "v"];
        key = "<leader>d";
        action = "\"_d";
      }
      {
        mode = ["x"];
        key = "<leader>p";
        action = "\"_dP";
      }
      {
        mode = ["n"];
        key = "N";
        action = "Nzz";
      }
      {
        mode = ["n"];
        key = "n";
        action = "nzz";
      }
      {
        mode = ["n"];
        key = "<C-u>";
        action = "<C-u>zz";
      }
      {
        mode = ["n"];
        key = "<C-d>";
        action = "<C-d>zz";
      }
      {
        mode = ["n"];
        key = "J";
        action = "mzJ1`z";
      }
      {
        mode = ["v"];
        key = "K";
        action = ":m '<-2<CR>gv=gv";
      }
      {
        mode = ["v"];
        key = "J";
        action = ":m '>+1<CR>gv=gv";
      }
      {
        mode = ["n"];
        key = "<leader>F";
        action = "mzgg=G`z";
      }
      {
        mode = ["n"];
        key = "Y";
        action = "y$";
      }
      {
        mode = ["n"];
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR><Esc>";
      }
      {
        mode = ["c"];
        key = "W";
        action = "w";
      }
      {
        mode = ["n"];
        key = "-";
        action = "<cmd>Oil<cr>";
      }
      {
        mode = ["n"];
        key = "<C-j>";
        action = "<cmd>cn<cr>";
      }
      {
        mode = ["n"];
        key = "<C-k>";
        action = "<cmd>cp<cr>";
      }
      {
        mode = ["t"];
        key = "<C-\\><C-\\>";
        action = "<C-\\><C-n>";
      }
      {
        mode = ["n"];
        key = "<C-cr>";
        action = "<cmd>term<cr>";
      }
    ];

    opts = {
      completeopt = ["menuone" "noselect" "noinsert"];
      cursorcolumn = true;
      cursorline = true;
      expandtab = true;
      ignorecase = true;
      incsearch = true;
      mouse = "";
      number = true;
      relativenumber = true;
      ruler = false;
      scrolloff = 7;
      shiftwidth = 4;
      showmode = false;
      signcolumn = "yes";
      smartcase = true;
      softtabstop = 4;
      swapfile = false;
      tabstop = 4;
      termguicolors = true;
      undofile = true;
      updatetime = 50;
      wrap = false;
      writebackup = false;
    };

    viAlias = true;
    luaLoader.enable = true;
    performance.combinePlugins = {
      enable = true;
      standalonePlugins = ["oil.nvim"];
    };

    colorschemes = {
      base16 = {
        enable = true;
        colorscheme = {
          base00 = "#${config.stylix.base16Scheme.base00}";
          base01 = "#${config.stylix.base16Scheme.base01}";
          base02 = "#${config.stylix.base16Scheme.base02}";
          base03 = "#${config.stylix.base16Scheme.base03}";
          base04 = "#${config.stylix.base16Scheme.base04}";
          base05 = "#${config.stylix.base16Scheme.base05}";
          base06 = "#${config.stylix.base16Scheme.base06}";
          base07 = "#${config.stylix.base16Scheme.base07}";
          base08 = "#${config.stylix.base16Scheme.base08}";
          base09 = "#${config.stylix.base16Scheme.base09}";
          base0A = "#${config.stylix.base16Scheme.base0A}";
          base0B = "#${config.stylix.base16Scheme.base0B}";
          base0C = "#${config.stylix.base16Scheme.base0C}";
          base0D = "#${config.stylix.base16Scheme.base0D}";
          base0E = "#${config.stylix.base16Scheme.base0E}";
          base0F = "#${config.stylix.base16Scheme.base0F}";
        };
      };
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    extraConfigLua = ''
      require('btw').setup({ text = "I use neovim (btw)" })

      local _border = "rounded"

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
          border = _border
        }
      )

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, {
          border = _border
        }
      )

      vim.diagnostic.config{
        float={border=_border}
      };

      require('lspconfig.ui.windows').default_options = {
        border = _border
      }
    '';

    extraPlugins = with pkgs.vimPlugins; [
      vim-visual-multi
      vim-indent-object
      (pkgs.vimUtils.buildVimPlugin {
        pname = "btw.nvim";
        version = "2024-04-36";
        src = pkgs.fetchFromGitHub {
          owner = "letieu";
          repo = "btw.nvim";
          rev = "47f6419e90d3383987fd06e8f3e06a4bc032ac83";
          hash = "sha256-91DZUfa4FBvXnkcNHdllr82Dr1Ie+MGVD3ibwkqo04c=";
        };
      })
    ];
  };
}
