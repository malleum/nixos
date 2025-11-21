{
  pkgs,
  lib,
  ...
}: {
  # vim-sexp vim-sexp-mappings-for-regular-people conjure.enable = true;
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
        "<leader>f" = "<cmd>lua require('conform').format({ async = true, lsp_fallback = true })<cr>";

        "<leader>a" = "<cmd>lua require('harpoon'):list():add()<cr>";
        "<leader>o" = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
        "<C-A-h>" = "<cmd>lua require('harpoon'):list():select(1)<cr>";
        "<C-A-n>" = "<cmd>lua require('harpoon'):list():select(3)<cr>";
        "<C-A-s>" = "<cmd>lua require('harpoon'):list():select(4)<cr>";
        "<C-A-t>" = "<cmd>lua require('harpoon'):list():select(2)<cr>";

        "<leader>pw" = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<cr>";
        "<leader>pW" = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') })<cr>";
        "<leader>pS" = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input({ prompt = ' > ' }) })<cr>";

        "<Esc>" = "<cmd>nohlsearch<CR><Esc>";
        "J" = ''<cmd>lua vim.cmd("normal! mz" .. vim.v.count1 .. "J`z")<cr>'';

        "<C-d>" = "<C-d>zz";
        "<C-u>" = "<C-u>zz";
        "N" = "Nzz";
        "n" = "nzz";
        "Y" = "y$";
      };

      "nv" = {
        "<leader>d" = "\"_d";
        "<leader>D" = "\"_D";
        "<leader>y" = "\"+y";
        "<leader>Y" = "\"+y$";
      };

      "x" = {"<leader>p" = "\"_dP";};

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
    servers = {
      clangd.enable = true;
      clojure_lsp.enable = true;
      gopls.enable = true;
      jdtls.enable = true;
      jsonls.enable = true;
      html.enable = true;
      ts_ls.enable = true;
      lua_ls.enable = true;
      nixd = {
        enable = true;
        config.offset_encoding = "utf-8";
      };
      pyright.enable = true;
      sqls.enable = true;
      tinymist = {
        enable = true;
        config = {
          exportPdf = "onSave";
          offset_encoding = "utf-8";
          root_dir = ''function(_, bufnr) return vim.fs.root(bufnr, { ".git" }) or vim.fn.expand("%:p:h") end'';
        };
      };
      zls.enable = true;
    };
    keymaps = let
      default = {
        "[d" = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
        "]d" = "<cmd>lua vim.diagnostic.goto_next()<cr>";
        "gl" = "<cmd>lua vim.diagnostic.open_float()<cr>";

        "gd" = lib.nixvim.mkRaw "require('telescope.builtin').lsp_definitions";
        "gr" = lib.nixvim.mkRaw "require('telescope.builtin').lsp_references";
      };
      lspBuf = {
        "K" = "hover";
        "gD" = "definition";
        "go" = "type_definition";
        "gR" = "references";
        "gs" = "signature_help";

        "<leader>rn" = "rename";
        "<leader>ra" = "code_action";
        "<leader>rr" = "references";
      };
    in
      (lib.mapAttrsToList (key: lspBufAction: {inherit key lspBufAction;}) lspBuf)
      ++ (lib.mapAttrsToList (key: action: {inherit key action;}) default);
  };

  extraPlugins = with pkgs.vimPlugins; [vim-visual-multi vim-indent-object];

  plugins = {
    lspconfig.enable = true;

    luasnip = {
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
        snippets.preset = "luasnip";
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

    comment.enable = true;
    diffview.enable = true;
    gitsigns.enable = true;
    neogit.enable = true;
    nvim-autopairs.enable = true;
    nvim-surround.enable = true;
    oil.enable = true;
    quicker.enable = true;
    todo-comments.enable = true;
    typst-preview.enable = true;
    web-devicons.enable = true;

    treesitter = {
      enable = true;
      settings.highlight.enable = true;
    };

    conform-nvim = {
      enable = true;
      autoInstall.enable = true;
      settings = {
        formatters_by_ft = {
          "*" = ["trim_whitespace"];
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
        border = true;
        layout_config.horizontal = {
          prompt_position = "top";
          width = 0.95;
          height = 0.85;
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

    harpoon = {
      enable = true;
      settings.menu = {
        width = 100;
        height = 6;
      };
    };
  };
}
