{pkgs, ...}: let
  ruff = "${pkgs.ruff}/bin/ruff";
  stylua = "${pkgs.stylua}/bin/stylua";
  alejandra = "${pkgs.alejandra}/bin/alejandra";
  isort = "${pkgs.isort}/bin/isort";
in {
  programs.nixvim = {
    plugins = {
      ccc.enable = true;
      comment.enable = true;
      diffview.enable = true;
      gitsigns.enable = true;
      neogit.enable = true;
      nvim-autopairs.enable = true;
      oil.enable = true;
      quickmath.enable = true;
      surround.enable = true;
      todo-comments.enable = true;
      treesitter = {
        enable = true;
        settings = {
          auto_install = true;
          highlight.enable = true;
        };
      };
      undotree.enable = true;
      vimtex.enable = true;

      conform-nvim = {
        enable = true;
        formatters = {
          ruff_format = {
            command = ruff;
            prepend_args = ["format"];
          };
          stylua.command = stylua;
          alejandra.command = alejandra;
          isort.command = isort;
        };
        formattersByFt = {
          lua = ["stylua"];
          nix = ["alejandra"];
          python = ["isort" "ruff_format"];
          "*" = ["trim_whitespace"];
        };
      };

      lint = {
        enable = true;
        linters.ruff.cmd = ruff;
        lintersByFt.python = ["ruff"];
      };

      lualine = {
        enable = true;
        sectionSeparators = {
          left = "";
          right = "";
        };
        componentSeparators = {
          left = "\\";
          right = "/";
        };
        sections = {
          lualine_a = [{name = "mode";}];
          lualine_b = [{name = "branch";} {name = "diff";} {name = "diagnostics";}];
          lualine_c = [{name = "filename";}];
          lualine_x = [{name = "selectioncount";} {name = "filetype";}];
          lualine_y = [{name = "encoding";} {name = "filexxformat";}];
          lualine_z = [{name = "location";}];
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>g";
        action = "<cmd>Neogit<cr>";
      }
      {
        mode = "n";
        key = "<leader>ut";
        action = "<cmd>UndotreeToggle<cr>";
      }
    ];

    extraPlugins = with pkgs.vimPlugins; [
      vim-visual-multi
      vim-indent-object
    ];
  };
}
