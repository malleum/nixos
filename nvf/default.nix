{
  pkgs,
  inputs,
  ...
}: {
  vim = {
    enableLuaLoader = false;
    package = inputs.neovim-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

    viAlias = true;

    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
    };

    statusline.lualine.enable = true;

    utility = {
      oil-nvim.enable = true;
    };

    telescope = {
      enable = true;
    };

    lsp = {
      enable = true;
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
    };

    options = {
      completeopt = "menuone,noselect,noinsert";
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
      undofile = true;
      updatetime = 50;
      winborder = "rounded";
      wrap = false;
    };

    maps = {
      normal = {
        "Y".action = "y$";
        "<Esc>".action = "<cmd>nohlsearch<CR><Esc>";
        "J" = {
          expr = true;
          silent = true;
          lua = true;
          action =
            /*
            lua
            */
            "function () return 'mz' .. vim.v.count1 .. 'J`z' end";
        };
      };
      visual = {
        "<leader>p".action = "\"_dP";
      };
      command = {
        "W".action = "w";
      };
      normalVisualOp = {
        "-".action = "<cmd>Oil<cr>";
        "<leader>D".action = "\"_D";
        "<leader>d".action = "\"_d";
        "<leader>Y".action = "\"+y$";
        "<leader>y".action = "\"+y";
        "<C-d>".action = "<C-d>zz";
        "<C-u>".action = "<C-u>zz";
        "N".action = "Nzz";
        "n".action = "nzz";
      };
    };
  };
}
