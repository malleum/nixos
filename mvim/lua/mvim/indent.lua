-- Indent text objects, vim-indent-object style.
--   ii  the block of lines at the current indent or deeper (blank lines included)
--   ai  the same plus the line above it (e.g. the `if` or function header)
local M = {}

local function blank(lnum) return vim.fn.getline(lnum):match("^%s*$") ~= nil end

function M.select(around)
  local last = vim.fn.line("$")
  local lnum = vim.fn.line(".")
  -- On a blank line, use the next non-blank line's indent.
  while lnum < last and blank(lnum) do
    lnum = lnum + 1
  end
  local indent = vim.fn.indent(lnum)

  local function inside(l) return blank(l) or vim.fn.indent(l) >= indent end

  local s, e = lnum, lnum
  while s > 1 and inside(s - 1) do
    s = s - 1
  end
  while e < last and inside(e + 1) do
    e = e + 1
  end
  -- Leading/trailing blank lines belong to the surrounding code, not the block.
  while s < e and blank(s) do
    s = s + 1
  end
  while e > s and blank(e) do
    e = e - 1
  end
  if around and s > 1 then
    s = s - 1
  end

  vim.cmd(("normal! %dGV%dG"):format(s, e))
end

function M.setup()
  for key, around in pairs({ ii = false, ai = true }) do
    vim.keymap.set(
      { "x", "o" },
      key,
      (":<C-u>lua require('mvim.indent').select(%s)<CR>"):format(around),
      { silent = true }
    )
  end
end

return M
