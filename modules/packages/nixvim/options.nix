{
  programs.nixvim = {
    opts = {
      completeopt = ["menuone" "noselect" "noinsert"];
      cursorcolumn = true;
      cursorline = true;
      expandtab = true;
      ignorecase = true;
      incsearch = true;
      mouse = "";
      nu = true;
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

    luaLoader.enable = true;
    viAlias = true;

    colorschemes.tokyonight = {
      enable = true;
      settings = {
        style = "night";
        transparent = true;
      };
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    keymaps = [
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
        mode = "t";
        key = "<C-\\><C-\\>";
        action = "<C-\\><C-n>";
      }
      {
        mode = "n";
        key = "<C-cr>";
        action = "<cmd>term<cr>";
      }
    ];
  };
}
