-- Minimal insert-mode pairing: brackets and quotes close themselves, typing
-- the closer steps over an existing one, <BS> in an empty pair deletes both,
-- and <CR> between brackets opens an indented line.
local M = {}

local pairs_ = { ["("] = ")", ["["] = "]", ["{"] = "}" }
local closers = { [")"] = true, ["]"] = true, ["}"] = true }
local quotes = { ['"'] = true, ["'"] = true, ["`"] = true }

-- <C-g>U keeps the cursor movement from breaking undo and dot-repeat.
local left = "<C-g>U<Left>"
local right = "<C-g>U<Right>"

local function around()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(col, col), line:sub(col + 1, col + 1)
end

function M.cr()
  local before, after = around()
  if pairs_[before] and pairs_[before] == after then
    return "<CR><C-o>O"
  end
  return "<CR>"
end

function M.setup()
  local map = function(lhs, fn) vim.keymap.set("i", lhs, fn, { expr = true }) end

  for open, close in pairs(pairs_) do
    map(open, function() return open .. close .. left end)
  end

  for close in pairs(closers) do
    map(close, function()
      local _, after = around()
      return after == close and right or close
    end)
  end

  for q in pairs(quotes) do
    map(q, function()
      local before, after = around()
      if after == q then
        return right
      end
      -- Apostrophes in words (don't) and escaped quotes stay single.
      if before:match("[%w\\]") or after:match("%w") then
        return q
      end
      return q .. q .. left
    end)
  end

  map("<BS>", function()
    local before, after = around()
    if (pairs_[before] and pairs_[before] == after) or (quotes[before] and before == after) then
      return "<BS><Del>"
    end
    return "<BS>"
  end)
end

return M
