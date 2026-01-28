{
  pkgs,
  lib,
  plena ? true,
  ...
}: {
  opts = {
    completeopt = ["menuone" "noselect" "noinsert"];
    cursorcolumn = true;
    cursorline = true;
    expandtab = true;
    ignorecase = true;
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
    winborder = "rounded";
    wrap = false;
  };

  package = pkgs.stable.neovim-unwrapped;

  viAlias = true;
  luaLoader.enable = true;
  performance.combinePlugins = {
    enable = true;
    standalonePlugins = ["oil.nvim" "conform.nvim" "typst-preview.nvim"];
  };

  colorscheme = "tokyonight";
  colorschemes.tokyonight = {
    enable = true;
    settings.style = "night";
  };

  globals = {
    mapleader = " ";
    maplocalleader = " ";
    loaded_netrw = 1;
    loaded_netrwPlugin = 1;
  };

  keymaps = let
    maps = {
      "n" = {
        "-" = "<cmd>Oil<cr>";
        "<leader>g" = "<cmd>Neogit<cr>";
        "<leader>q" = "<cmd>lua require('quicker').toggle()<cr>";
        "<leader>f" = "<cmd>lua require('conform').format({ async = true, lsp_fallback = true })<cr>";

        "<leader>a" = "<cmd>lua require('harpoon'):list():add()<cr>";
        "<leader>o" = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
        "<C-A-h>" = "<cmd>lua require('harpoon'):list():select(1)<cr>";
        "<C-A-n>" = "<cmd>lua require('harpoon'):list():select(3)<cr>";
        "<C-A-s>" = "<cmd>lua require('harpoon'):list():select(4)<cr>";
        "<C-A-t>" = "<cmd>lua require('harpoon'):list():select(2)<cr>";

        "<leader>t" = "<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.expand('%:p:h') })<cr>";
        "<leader>pw" = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<cr>";
        "<leader>pW" = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') })<cr>";
        "<leader>pS" = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input({ prompt = ' > ' }) })<cr>";
      };

      "nv" = {
        "<leader>d" = "\"_d";
        "<leader>D" = "\"_D";
        "<leader>y" = "\"+y";
        "<leader>Y" = "\"+y$";

        "<Esc>" = "<cmd>nohlsearch<CR><Esc>";
        "J" = ''<cmd>lua vim.cmd("normal! mz" .. vim.v.count1 .. "J`z")<cr>'';
        "s" = "<cmd>lua require('flash').jump()<cr>";

        "<C-j>" = "<cmd>cn<cr>";
        "<C-k>" = "<cmd>cp<cr>";

        "<C-d>" = "<C-d>zz";
        "<C-u>" = "<C-u>zz";
        "N" = "Nzz";
        "n" = "nzz";
      };

      "x" = {
        "<leader>p" = "\"_dP";
        "<leader>h" = "lua require('telescope.builtin').grep_string({ search = vim.fn.getreg('\"') })";
      };

      "c" = {"W" = "w";};

      "i" = {"<A-c>" = "<C-o>S<C-r>=<C-r>\"<CR>";};

      "is" = {
        "<C-j>" = "<cmd>lua require('luasnip').jump(1)<cr>";
        "<C-k>" = "<cmd>lua require('luasnip').jump(-1)<cr>";
      };
    };
  in
    lib.flatten (lib.mapAttrsToList (mode: mappings:
      lib.mapAttrsToList (key: action: {
        mode = lib.stringToCharacters mode;
        inherit key action;
      })
      mappings)
    maps);

  lsp = {
    inlayHints.enable = true;
    servers = lib.mkIf plena {
      elmls.enable = true;
      elixir.enable = true;
      clangd.enable = true;
      clojure_lsp.enable = true;
      gopls.enable = true;
      jdtls.enable = true;
      jsonls.enable = true;
      html.enable = true;
      ts_ls.enable = true;
      ltex_plus = {
        enable = true;
        package = pkgs.ltex-ls-plus;
      };
      lua_ls = {
        enable = true;
        settings.Lua.diagnostics.globals = ["vim"];
      };
      nixd = {
        enable = true;
        config.offset_encoding = "utf-8";
      };
      ty.enable = true;
      rust_analyzer.enable = true;
      sqls.enable = true;
      tinymist = {
        enable = true;
        config = {
          offset_encoding = "utf-8";
          settings = {
            exportPdf = "onSave";
            root_dir = ''function(_, bufnr) return vim.fs.root(bufnr, { ".git" }) or vim.fn.expand("%:p:h") end'';
          };
        };
      };
      zls.enable = true;
    };
    keymaps = let
      default = {
        "[d" = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
        "]d" = "<cmd>lua vim.diagnostic.goto_next()<cr>";
        "gl" = "<cmd>lua vim.diagnostic.open_float()<cr>";

        "gd" = "<cmd>lua require('telescope.builtin').lsp_definitions()<cr>";
        "gr" = "<cmd>lua require('telescope.builtin').lsp_references()<cr>";
      };
      lspBuf = {
        "K" = "hover";
        "gD" = "definition";
        "go" = "type_definition";
        "gR" = "references";

        "<leader>rn" = "rename";
        "<leader>ra" = "code_action";
      };
    in
      (lib.mapAttrsToList (key: lspBufAction: {inherit key lspBufAction;}) lspBuf)
      ++ (lib.mapAttrsToList (key: action: {inherit key action;}) default);
  };

  extraPlugins = with pkgs.vimPlugins; [vim-visual-multi vim-indent-object];

  plugins = {
    lspconfig.enable = plena;

    luasnip = lib.mkIf plena {
      enable = true;
      settings = {
        enable_autosnippets = true;
        store_selection_keys = "<Tab>";
        history = true;
        update_events = "TextChanged,TextChangedI";
      };
      fromVscode = [
        {
          lazyLoad = true;
          paths = "${pkgs.vimPlugins.friendly-snippets}";
        }
      ];
    };

    blink-cmp = {
      enable = true;
      settings = {
        snippets = lib.mkIf plena {preset = "luasnip";};
        keymap = {
          preset = "default";
          "<C-p>" = ["select_prev" "show"];
          "<C-n>" = ["select_next" "show"];
          "<CR>" = ["accept" "fallback"];
          "<C-b>" = ["scroll_documentation_up" "fallback"];
          "<C-f>" = ["scroll_documentation_down" "fallback"];
        };
        sources.default = ["lsp" "path" "snippets" "buffer"];
        completion = {
          menu = {
            border = "rounded";
            draw = {
              columns = [
                {__unkeyed-1 = "kind_icon";}
                {
                  __unkeyed-1 = "label";
                  __unkeyed-2 = "label_description";
                  gap = 1;
                }
                {__unkeyed-1 = "kind";}
              ];
            };
          };
          documentation = {
            window.border = "rounded";
            auto_show = true;
            auto_show_delay_ms = 200;
          };
          ghost_text.enabled = true;
        };
        signature.enabled = true;
      };
    };

    csvview.enable = true;
    diffview.enable = true;
    gitsigns.enable = true;
    harpoon.enable = true;
    neogit.enable = true;
    nvim-autopairs.enable = true;
    nvim-surround.enable = true;
    oil.enable = true;
    quicker.enable = true;
    quickmath.enable = true;
    todo-comments.enable = true;
    typst-preview.enable = true;
    web-devicons.enable = true;

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

    treesitter = lib.mkIf plena {
      enable = true;
      # package = pkgs.stable.vimPlugins.nvim-treesitter.withAllGrammars;
      # nixGrammars = false;
      settings.highlight.enable = true;
    };

    conform-nvim = {
      enable = true;
      autoInstall.enable = plena;
      settings = {
        formatters_by_ft = {
          "*" = ["trim_whitespace"];
          go = ["goimports" "gofmt"];
          javascript = ["prettierd"];
          lua = ["stylua"];
          nix = ["alejandra"];
          python = ["isort" "ruff_format"];
          rust = ["rustfmt"];
          typst = ["typstyle"];
          elixir = ["mix"];
          elm = ["elm_format"];
        };
      };
    };

    lint = lib.mkIf plena {
      enable = true;
      linters.ruff.cmd = "${pkgs.ruff}/bin/ruff";
      lintersByFt.python = ["ruff"];
    };
    lualine = {
      enable = true;
      settings = {
        sections = {
          lualine_a = ["mode"];
          lualine_b = ["branch" "diff"];
          lualine_c = ["diagnostics"];
          lualine_x = ["filetype"];
          lualine_y = ["progress"];
          lualine_z = ["location"];
        };
      };
    };

    telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      settings.defaults = {
        layout_config.horizontal = {
          prompt_position = "top";
          width = 0.95;
        };
      };
      keymaps = {
        "<leader>h" = "find_files";
        "<leader>pg" = "git_files";
        "<leader>ps" = "live_grep";
        "<leader>pr" = "lsp_references";
        "<leader>pd" = "diagnostics";
        "<leader>ph" = "help_tags";
        "<leader>pt" = "todo-comments";
      };
    };
  };

  extraFiles = {
    "lua/penger.lua".source = ./penger.lua;
    "plugin/penger_init.lua".text = ''
      require("penger").setup()
    '';
    "ftdetect/ago.lua".text = ''
      vim.filetype.add({
        extension = {
          ago = "ago",
        },
      })
    '';
    "syntax/ago.vim".source = ./ago.vim;
  };
}
