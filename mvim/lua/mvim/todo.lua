-- Highlights TODO-style keywords. Without treesitter comment parsing this
-- matches anywhere in the buffer, not just inside comments.
local M = {}

-- `link` names the group whose foreground color each keyword borrows. These
-- are core groups every colorscheme sets, so any scheme gives on-palette badges.
local groups = {
  MvimTodoFix = { link = "Error", words = { "FIX", "FIXME", "BUG", "FIXIT", "ISSUE" } },
  MvimTodoTodo = { link = "Function", words = { "TODO" } },
  MvimTodoHack = { link = "Type", words = { "HACK", "WARN", "WARNING", "XXX" } },
  MvimTodoNote = { link = "String", words = { "NOTE", "INFO" } },
  MvimTodoPerf = { link = "Keyword", words = { "PERF", "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
}

local function add_matches()
  if vim.w.mvim_todo then
    return
  end
  vim.w.mvim_todo = true
  for group, spec in pairs(groups) do
    vim.fn.matchadd(group, [[\v<(]] .. table.concat(spec.words, "|") .. [[)>:?]])
  end
end

-- ripgrep regex for keywords followed by a colon, e.g. "TODO:" or "NOTE:".
function M.rg_pattern()
  local words = {}
  for _, spec in pairs(groups) do
    vim.list_extend(words, spec.words)
  end
  table.sort(words)
  return [[\b(]] .. table.concat(words, "|") .. [[):]]
end

-- Keywords get their diagnostic color as the background, with the editor
-- background as text so they read as a badge. Reapplied on :colorscheme.
local function set_highlights()
  local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  for group, spec in pairs(groups) do
    local color = vim.api.nvim_get_hl(0, { name = spec.link, link = false }).fg
    vim.api.nvim_set_hl(0, group, { bg = color, fg = normal_bg, bold = true })
  end
end

function M.setup()
  set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })
  vim.api.nvim_create_autocmd({ "VimEnter", "WinNew", "BufWinEnter" }, { callback = add_matches })
end

return M
