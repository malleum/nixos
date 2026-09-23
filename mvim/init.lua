-- mvim: plugin-free neovim config, packaged by modules/meta/nvim.nix.
-- Keys and features are documented in doc/mvim.txt: `:help mvim`.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- No providers are packaged; skip probing for them at startup.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

local o = vim.opt
o.completeopt = { "menuone", "noselect", "noinsert", "fuzzy", "popup" }
o.cursorcolumn = true
o.cursorline = true
o.expandtab = true
o.ignorecase = true
o.mouse = ""
o.number = true
o.relativenumber = true
o.ruler = false
o.scrolloff = 7
o.shiftwidth = 4
o.showmode = false
o.signcolumn = "yes"
o.smartcase = true
o.softtabstop = 4
o.swapfile = false
o.tabstop = 4
o.termguicolors = true
o.undofile = true
o.updatetime = 50
o.winborder = "rounded"
o.wrap = false
o.sessionoptions:append("localoptions")

-- Tokyonight night: colors/tokyonight.lua (vendored; bat's theme matches).
-- Built-in alternatives (`:colorscheme <Tab>` to preview):
--   blue catppuccin darkblue default delek desert elflord evening habamax
--   industry koehler lunaperche morning murphy pablo peachpuff quiet retrobox
--   ron shine slate sorbet torte unokai vim wildcharm zaibatsu zellner
vim.cmd.colorscheme("tokyonight")

require("mvim.keymaps")
require("mvim.direnv").setup()
-- Before lsp: a dev shell's lsp/<name>.lua has to be on the runtimepath before
-- servers are enabled, on startup and again after :Direnv.
require("mvim.shellrtp").setup()
require("mvim.lsp")
require("mvim.lsp_keys")
require("mvim.treesitter")
require("mvim.picker").setup()
require("mvim.dirbuf").setup()
require("mvim.surround").setup()
require("mvim.indent").setup()
require("mvim.autopairs").setup()
require("mvim.format").setup()
require("mvim.todo").setup()
require("mvim.gitsigns").setup()
require("mvim.session").setup()

-- Reopen files at the last cursor position.
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    if vim.bo[args.buf].filetype == "gitcommit" then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- The multicursor and git modules are the largest; they load on first use.
local function lazy(module, fn, ...)
  local args = { ... }
  return function() return require(module)[fn](unpack(args)) end
end
local map = vim.keymap.set
map("n", "<C-n>", lazy("mvim.multicursor", "word"), { desc = "Multicursor: word under cursor / next match" })
map("x", "<C-n>", lazy("mvim.multicursor", "visual"), { desc = "Multicursor: selected text, or cursors on lines" })
map("n", "<C-Down>", lazy("mvim.multicursor", "vertical", 1), { desc = "Multicursor: add cursor below" })
map("n", "<C-Up>", lazy("mvim.multicursor", "vertical", -1), { desc = "Multicursor: add cursor above" })
map("n", "<leader>g", lazy("mvim.git", "open"), { desc = "Git status page" })
vim.api.nvim_create_user_command(
  "GitBlame",
  function(opts) require("mvim.git").blame(opts.line1, opts.line2) end,
  { range = true, desc = "Who last changed these lines" }
)

-- Spell checking for prose. In treesitter buffers only text is checked, not
-- code or markup.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "gitcommit", "typst", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})
