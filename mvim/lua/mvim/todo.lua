-- TODO-style keywords as colored badges, in comments only. Treesitter's
-- `comment` grammar is injected into comments and tags the keywords with the
-- @comment.* groups below (C, Lua and Vim script get the injection from
-- mvim/queries). Files without treesitter use regex syntax, whose Todo group
-- covers TODO/FIXME/XXX in comments.
local M = {}

-- Each group borrows the foreground of `link` (core groups every colorscheme
-- sets) as its background. `words` are what the comment grammar tags.
local groups = {
  ["@comment.error"] = { link = "Error", words = { "FIXME", "BUG", "ERROR" } },
  ["@comment.warning"] = { link = "Type", words = { "HACK", "WARNING", "WARN", "FIX" } },
  ["@comment.todo"] = { link = "Function", words = { "TODO", "WIP" } },
  ["@comment.note"] = { link = "String", words = { "NOTE", "XXX", "INFO", "DOCS", "PERF", "TEST" } },
  Todo = { link = "Function", words = {} },
}

-- ripgrep regex for keywords followed by a colon, e.g. "TODO:" or "NOTE:".
function M.rg_pattern()
  local words = {}
  for _, spec in pairs(groups) do
    vim.list_extend(words, spec.words)
  end
  table.sort(words)
  return [[\b(]] .. table.concat(words, "|") .. [[):]]
end

-- Reapplied on :colorscheme, since schemes set these groups themselves.
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
end

return M
