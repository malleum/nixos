-- Highlights TODO-style keywords. Without treesitter comment parsing this
-- matches anywhere in the buffer, not just inside comments.
local M = {}

local groups = {
  MvimTodoFix = { link = "DiagnosticError", words = { "FIX", "FIXME", "BUG", "FIXIT", "ISSUE" } },
  MvimTodoTodo = { link = "DiagnosticInfo", words = { "TODO" } },
  MvimTodoHack = { link = "DiagnosticWarn", words = { "HACK", "WARN", "WARNING", "XXX" } },
  MvimTodoNote = { link = "DiagnosticHint", words = { "NOTE", "INFO" } },
  MvimTodoPerf = { link = "DiagnosticOk", words = { "PERF", "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
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

function M.setup()
  for group, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, group, { link = spec.link, default = true })
  end
  vim.api.nvim_create_autocmd({ "VimEnter", "WinNew", "BufWinEnter" }, { callback = add_matches })
end

return M
