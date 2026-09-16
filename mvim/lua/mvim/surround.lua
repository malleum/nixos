-- nvim-surround style add/change/delete of delimiter pairs.
--   ys{motion}{char}  yss{char}  ds{char}  cs{old}{new}  visual S{char}
-- An opening bracket adds (or, for ds/cs, also removes) inner spaces:
-- ys iw ( gives "( word )", ys iw ) gives "(word)".
local M = {}

local api = vim.api

local brackets = { ["("] = ")", ["["] = "]", ["{"] = "}", ["<"] = ">" }
local closers = { [")"] = "(", ["]"] = "[", ["}"] = "{", [">"] = "<" }
local aliases = { b = ")", B = "}", r = "]", a = ">" }

-- Returns open, close, and whether the pair is padded with spaces.
local function pair(char)
  char = aliases[char] or char
  if brackets[char] then
    return char, brackets[char], true
  elseif closers[char] then
    return closers[char], char, false
  end
  return char, char, false
end

local function getchar()
  local ok, c = pcall(vim.fn.getcharstr)
  if not ok or c == "\27" then
    return nil
  end
  return c
end

-- Byte length of the character starting at 0-based `col` on `line`.
local function char_len(line, col)
  if col >= #line then
    return 0
  end
  return vim.str_utf_end(line, col + 1) + 1
end

-- Wraps the 0-based, end-inclusive range [srow:scol, erow:ecol].
local function wrap(srow, scol, erow, ecol, char)
  local open, close, pad = pair(char)
  if pad then
    open, close = open .. " ", " " .. close
  end
  local last = api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]
  local ecol_excl = math.min(ecol + char_len(last, ecol), #last)
  api.nvim_buf_set_text(0, erow, ecol_excl, erow, ecol_excl, { close })
  api.nvim_buf_set_text(0, srow, scol, srow, scol, { open })
end

local function wrap_lines(srow, erow, char)
  local first = api.nvim_buf_get_lines(0, srow, srow + 1, true)[1]
  local last = api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]
  local scol = #first:match("^%s*")
  wrap(srow, scol, erow, math.max(#last - 1, 0), char)
end

local last_char
function M.opfunc(type)
  local char = M._repeat and last_char or getchar()
  M._repeat = true
  if not char then
    return
  end
  last_char = char
  local s = api.nvim_buf_get_mark(0, "[")
  local e = api.nvim_buf_get_mark(0, "]")
  if type == "line" then
    wrap_lines(s[1] - 1, e[1] - 1, char)
  else
    wrap(s[1] - 1, s[2], e[1] - 1, e[2], char)
  end
end

function M.visual()
  local char = getchar()
  if not char then
    return
  end
  local s = api.nvim_buf_get_mark(0, "<")
  local e = api.nvim_buf_get_mark(0, ">")
  if vim.fn.visualmode() == "V" then
    wrap_lines(s[1] - 1, e[1] - 1, char)
  else
    local line = api.nvim_buf_get_lines(0, e[1] - 1, e[1], true)[1]
    wrap(s[1] - 1, s[2], e[1] - 1, math.min(e[2], math.max(#line - 1, 0)), char)
  end
end

-- Finds the pair around the cursor. Returns 0-based {row, col} of the opening
-- and closing delimiters, or nil.
local function find(char)
  local open, close = pair(char)
  local cursor = api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  if open == close then
    local line = api.nvim_get_current_line()
    local left, right
    for i = col + 1, 1, -1 do
      if line:sub(i, i) == open then
        left = i
        break
      end
    end
    if not left then
      return nil
    end
    right = line:find(open, math.max(left, col + 1) + 1, true)
    if left == col + 1 and not right then
      -- Cursor is on the closing quote: look left for the opener instead.
      right = left
      for i = left - 1, 1, -1 do
        if line:sub(i, i) == open then
          left = i
          break
        end
      end
      if left == right then
        return nil
      end
    end
    if not right then
      return nil
    end
    return { row, left - 1 }, { row, right - 1 }
  end

  local view = vim.fn.winsaveview()
  local esc_open, esc_close = vim.fn.escape(open, "[]"), vim.fn.escape(close, "[]")
  local under = api.nvim_get_current_line():sub(col + 1, col + 1)
  local o
  if under == open then
    o = { row + 1, col + 1 }
  else
    o = vim.fn.searchpairpos(esc_open, "", esc_close, "bW")
  end
  local c = { 0, 0 }
  if o[1] > 0 then
    api.nvim_win_set_cursor(0, { o[1], o[2] - 1 })
    c = vim.fn.searchpairpos(esc_open, "", esc_close, "nW")
  end
  vim.fn.winrestview(view)
  if o[1] == 0 or c[1] == 0 then
    return nil
  end
  return { o[1] - 1, o[2] - 1 }, { c[1] - 1, c[2] - 1 }
end

-- Replaces the delimiters found for `old` with `new_open`/`new_close`.
local function replace(old, new_open, new_close)
  local o, c = find(old)
  if not o then
    return
  end
  local _, _, pad = pair(old)
  local cline = api.nvim_buf_get_lines(0, c[1], c[1] + 1, true)[1]
  local oline = api.nvim_buf_get_lines(0, o[1], o[1] + 1, true)[1]
  local cstart, cend = c[2], c[2] + 1
  local ostart, oend = o[2], o[2] + 1
  -- "( x )": drop one inner space on each side, but never the same space twice.
  local distinct = o[1] ~= c[1] or c[2] - o[2] >= 3
  if pad and distinct and oline:sub(o[2] + 2, o[2] + 2) == " " and cline:sub(c[2], c[2]) == " " then
    oend = oend + 1
    cstart = cstart - 1
  end
  api.nvim_buf_set_text(0, c[1], cstart, c[1], cend, { new_close })
  api.nvim_buf_set_text(0, o[1], ostart, o[1], oend, { new_open })
end

function M.delete()
  local char = getchar()
  if char then
    replace(char, "", "")
  end
end

function M.change()
  local old = getchar()
  local new = old and getchar()
  if not new then
    return
  end
  local open, close, pad = pair(new)
  if pad then
    open, close = open .. " ", " " .. close
  end
  replace(old, open, close)
end

function M.setup()
  local opfunc = "v:lua.require'mvim.surround'.opfunc"
  vim.keymap.set("n", "ys", function()
    M._repeat = false
    vim.o.operatorfunc = opfunc
    return "g@"
  end, { expr = true })
  vim.keymap.set("n", "yss", function()
    M._repeat = false
    vim.o.operatorfunc = opfunc
    return "g@_"
  end, { expr = true })
  vim.keymap.set("n", "ds", M.delete)
  vim.keymap.set("n", "cs", M.change)
  vim.keymap.set("x", "S", ":<C-u>lua require('mvim.surround').visual()<CR>", { silent = true })
end

return M
