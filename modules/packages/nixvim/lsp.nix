{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    plugins = {
      fidget.enable = true;
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          clangd.enable = true;
          dartls.enable = true;
          gleam.enable = true;
          gopls.enable = true;
          html.enable = true;
          htmx.enable = true;
          java-language-server.enable = true;
          jsonls.enable = true;
          kotlin-language-server.enable = true;
          lua-ls.enable = true;
          marksman.enable = true;
          nil-ls.enable = true;
          nixd.enable = true;
          pyright.enable = true;
          rust-analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
          tsserver.enable = true;
          vhdl-ls.enable = true;
        };
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
        onAttach = ''
          vim.keymap.set("n", "<leader>f", function() require("conform").format({ async = true, lsp_fallback = true }) end)
        '';
      };
      luasnip = {
        enable = true;
        extraConfig = {
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
    extraConfigLua = ''
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
  };
}
