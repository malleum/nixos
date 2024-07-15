{
  programs.nixvim = {
    plugins = {
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
          "<leader>pp" = "find_files";
          "<C-p>" = "git_files";
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
    };

    keymaps = [
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
        mode = "o";
        key = "r";
        action = "<cmd>lua require('flash').remote()<cr>";
      }
      {
        mode = ["x" "o"];
        key = "R";
        action = "<cmd>lua require('flash').treesitter_search()<cr>";
      }
    ];
  };
}
