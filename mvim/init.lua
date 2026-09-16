-- mvim: plugin-free neovim config, packaged by modules/meta/nvim.nix.
--
-- Keymaps that changed from the nixvim config (old -> new). Anything not
-- listed kept its old key.
--
--   LSP (now neovim 0.12 defaults)
--     <leader>rn  rename               -> grn
--     <leader>ra  code action          -> gra
--     gD          definition           -> <C-]>   (tagfunc is LSP-backed)
--     gd          telescope defs       -> <C-]>   (gd is vim's local-declaration again)
--     go          type definition      -> grt
--     gR / gr     references           -> grr     (fills the quickfix list)
--     <leader>pr  telescope references -> grr
--     gl          diagnostic float     -> <C-w>d
--     [d / ]d     diagnostic jumps     -> [d / ]d (now built in)
--     K           hover                -> K       (mapped on LspAttach; K is <Nop> elsewhere)
--     (none)      implementation       -> gri
--     (none)      document symbols     -> gO
--     (none)      signature help       -> <C-s>   (insert mode)
--
--   Pickers (fzf in a float instead of telescope)
--     <leader>h, <leader>t, <leader>pg, <leader>ps, <leader>pw, <leader>pW,
--     <leader>pS, <leader>pt (TODO:/FIXME:/NOTE:/... comments), and visual
--     <leader>h all kept.
--     <leader>pd  diagnostics          -> :lua vim.diagnostic.setqflist()
--     <leader>ph  help tags            -> :help <Tab>
--
--   Removed along with their plugins
--     -           oil                  -> gone (netrw stays disabled)
--     <leader>g   neogit               -> gone
--     <leader>q   quicker              -> :copen / :cclose
--     <leader>a, <leader>o, <C-A-h/t/n/s>  harpoon -> gone (file marks: mA, 'A)
--     <C-j>/<C-k> luasnip jumps (insert) -> gone (LSP snippets use <Tab>/<S-Tab>)
--     <C-b>/<C-f> blink doc scroll     -> gone
--     <CR>        blink accept         -> <CR> accepts the selected completion
--
--   Surround (hand-written, nvim-surround style)
--     ys{motion}{char}, yss{char}, ds{char}, cs{old}{new}, visual S{char}

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

-- Built-in colorschemes (`:colorscheme <Tab>` to preview):
--   blue catppuccin darkblue default delek desert elflord evening habamax
--   industry koehler lunaperche morning murphy pablo peachpuff quiet retrobox
--   ron shine slate sorbet torte unokai vim wildcharm zaibatsu zellner
vim.cmd.colorscheme("default")

require("mvim.keymaps")
require("mvim.lsp")
require("mvim.treesitter")
require("mvim.picker").setup()
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
