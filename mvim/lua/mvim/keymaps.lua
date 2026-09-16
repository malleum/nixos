-- Editing maps carried over from the nixvim config. Plugin-backed maps live
-- in their own modules.
local maps = {
  n = {
    ["K"] = "<Nop>",
  },
  nv = {
    ["<leader>d"] = '"_d',
    ["<leader>D"] = '"_D',
    ["<leader>y"] = '"+y',
    ["<leader>Y"] = '"+y$',

    ["<Esc>"] = "<cmd>nohlsearch<CR><Esc>",
    ["J"] = '<cmd>lua vim.cmd("normal! mz" .. vim.v.count1 .. "J`z")<cr>',

    ["<C-j>"] = "<cmd>cn<cr>",
    ["<C-k>"] = "<cmd>cp<cr>",

    ["<C-d>"] = "<C-d>zz",
    ["<C-u>"] = "<C-u>zz",
    ["N"] = "Nzz",
    ["n"] = "nzz",
  },
  x = {
    ["<leader>p"] = '"_dP',
  },
  c = {
    ["W"] = "w",
  },
  i = {
    ["<A-c>"] = '<C-o>S<C-r>=<C-r>"<CR>',
  },
}

for modes, mappings in pairs(maps) do
  for key, action in pairs(mappings) do
    vim.keymap.set(vim.split(modes, ""), key, action)
  end
end
