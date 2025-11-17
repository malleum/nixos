{pkgs, ...}: {
  plugins = {
    fidget.enable = true;
    lsp = {
      enable = true;
      servers = {
        clangd.enable = true;
        clojure_lsp.enable = true;
        gopls.enable = true;
        jdtls.enable = true;
        jsonls.enable = true;
        html.enable = true;
        ts_ls.enable = true;
        lua_ls = {
          enable = true;
          settings.Lua = {
            runtime.version = "LuaJIT";
            diagnostics.globals = ["vim"];
            workspace = {
              checkThirdParty = false;
              library = [
                "${pkgs.neovim-unwrapped}/share/nvim/runtime/lua"
                "${pkgs.neovim-unwrapped}/share/nvim/runtime/plugin"
              ];
            };
          };
        };
        nixd = {
          enable = true;
          settings = {};
          extraOptions.offset_encoding = "utf-8";
        };
        pyright.enable = true;
        sqls.enable = true;
        tinymist = {
          enable = true;
          extraOptions.offset_encoding = "utf-8";
          settings = {
            exportPdf = "onSave";
            root_dir =
              # lua
              ''
                function(_, bufnr)
                  return vim.fs.root(bufnr, { ".git" }) or vim.fn.expand("%:p:h")
                end
              '';
          };
        };
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
    lspkind = {
      enable = true;
      settings = {
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
        formatting.fields = [
          "kind"
          "abbr"
          "menu"
        ];

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
  extraConfigLua =
    #lua
    ''
      vim.diagnostic.config{
        float = { border = _border }
      }
    '';
}
