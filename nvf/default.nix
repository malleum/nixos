{
  pkgs,
  inputs,
  ...
}:
{
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

    keymaps = [
      # nixfmt: freeze=true
      {
        mode = [ "n" ];
        key = "-";
        action = "<cmd>Oil<cr>";
      }
      {
        mode = [ "x" ];
        key = "<leader>p";
        action = "\"_dP";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>D";
        action = "\"_D";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>d";
        action = "\"_d";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>Y";
        action = "\"+y$";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>y";
        action = "\"+y";
      }
      {
        mode = [ "n" ];
        key = "Y";
        action = "y$";
      }
      {
        mode = [ "n" ];
        key = "<C-d>";
        action = "<C-d>zz";
      }
      {
        mode = [ "n" ];
        key = "<C-u>";
        action = "<C-u>zz";
      }
      {
        mode = [ "n" ];
        key = "J";
        expr = true;
        silent = true;
        lua = true;
        action = "function () return 'mz' .. vim.v.count1 .. 'J`z' end";
      }
      {
        mode = [ "n" ];
        key = "N";
        action = "Nzz";
      }
      {
        mode = [ "n" ];
        key = "n";
        action = "nzz";
      }
      {
        mode = [ "n" ];
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR><Esc>";
      }
      {
        mode = [ "c" ];
        key = "W";
        action = "w";
      }
      # nixfmt: freeze=true
    ];
  };
}
