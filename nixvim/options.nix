{
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
  # package = inputs.neovim-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # performance.combinePlugins.enable = true;

  colorscheme = "tokyonight";
  colorschemes.tokyonight = {
    enable = true;
    settings = {
      style = "night";
      transparent = true;
    };
  };

  globals = {
    mapleader = " ";
    maplocalleader = ",";
    loaded_netrw = 1;
    loaded_netrwPlugin = 1;
  };

  keymaps = [
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
      options.silent = true;
      options.expr = true;
      action.__raw = ''function () return 'mz' .. vim.v.count1 .. 'J`z' end'';
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
  ];
}
