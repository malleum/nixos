{
  plugins = {
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
      };
    };

    harpoon = {
      enable = true;
      settings.menu = {
        width = 100;
        height = 6;
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
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>a";
      action.__raw = "function() require'harpoon':list():add() end";
    }
    {
      mode = "n";
      key = "<leader>o";
      action.__raw = "function() require'harpoon'.ui:toggle_quick_menu(require'harpoon':list()) end";
    }
    {
      mode = "n";
      key = "<C-A-h>";
      action.__raw = "function() require'harpoon':list():select(1) end";
    }
    {
      mode = "n";
      key = "<C-A-t>";
      action.__raw = "function() require'harpoon':list():select(2) end";
    }
    {
      mode = "n";
      key = "<C-A-n>";
      action.__raw = "function() require'harpoon':list():select(3) end";
    }
    {
      mode = "n";
      key = "<C-A-s>";
      action.__raw = "function() require'harpoon':list():select(4) end";
    }
    {
      mode = [ "n" ];
      key = "<leader>pt";
      action = "<cmd>TodoTelescope<cr>";
    }
    {
      mode = [ "n" ];
      key = "<leader>pS";
      action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input({ prompt = ' > ' }) })<cr>";
    }
    {
      mode = [ "n" ];
      key = "<leader>pw";
      action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<cr>";
    }
    {
      mode = [ "n" ];
      key = "<leader>pW";
      action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') })<cr>";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = "<cmd>lua require('flash').jump()<cr>";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action = "<cmd>lua require('flash').treesitter()<cr>";
    }
    {
      mode = [ "o" ];
      key = "r";
      action = "<cmd>lua require('flash').remote()<cr>";
    }
    {
      mode = [
        "x"
        "o"
      ];
      key = "R";
      action = "<cmd>lua require('flash').treesitter_search()<cr>";
    }
  ];
}
