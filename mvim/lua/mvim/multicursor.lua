-- Multiple cursors, modeled on vim-visual-multi's keys. Edits are made once at
-- the cursor you're on, then repeated with `.` at every other cursor when the
-- change finishes (on leaving insert mode, or right away for normal-mode
-- changes). One `u` undoes the change everywhere.
--
-- Start:
--   <C-n>              select the word under the cursor (whole word)
--   visual <C-n>       charwise: select the selected text (no word boundaries)
--                      linewise/blockwise: a cursor on every selected line, at
--                      the cursor's column (block: its left edge)
--   <C-Down> / <C-Up>  add a cursor on the line below / above
--
-- While active:
--   <C-n> / n  add the next match       N  add the previous match
--   q          skip this match, add the next
--   Q          remove the cursor/selection you're on
--   ] / [      go to the next / previous cursor
--   c d        change / delete every selection (selections only)
--   i a        insert before / append after every selection (selections only)
--   <Esc>      stop
-- Motions (w, e, $, f,, 3j, gg, ...) run at every cursor as soon as they
-- finish, so the cursors move together; selections become cursors once moved.
-- Anything that changes text (ciw, x, A, p, ...) is repeated with `.` at every
-- cursor, at the same offset from it. Searches typed with / only move this one.
local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("mvim_multicursor")
local ns_tmp = api.nvim_create_namespace("mvim_multicursor_replay")
local ns_keys = api.nvim_create_namespace("mvim_multicursor_keys")

local state -- nil when inactive

local function pos(region)
  local mark = api.nvim_buf_get_extmark_by_id(state.buf, ns, region.id, { details = true })
  return { row = mark[1], col = mark[2], end_row = mark[3].end_row, end_col = mark[3].end_col }
end

local function add_region(row, col, end_col, kind)
  local line = api.nvim_buf_get_lines(state.buf, row, row + 1, true)[1]
  col = math.max(0, math.min(col, math.max(#line - 1, 0)))
  local id = api.nvim_buf_set_extmark(state.buf, ns, row, col, {
    end_row = row,
    end_col = kind == "cursor" and col + 1 or end_col,
    hl_group = kind == "cursor" and "MvimCursor" or "MvimSelection",
    right_gravity = false,
    end_right_gravity = true,
    strict = false,
    priority = 200,
  })
  local region = { id = id, kind = kind }
  table.insert(state.regions, region)
  return region
end

local function remove_region(region)
  api.nvim_buf_del_extmark(state.buf, ns, region.id)
  for i, r in ipairs(state.regions) do
    if r == region then
      table.remove(state.regions, i)
      break
    end
  end
end

local function sorted()
  local list = vim.tbl_map(function(r) return { region = r, pos = pos(r) } end, state.regions)
  table.sort(
    list,
    function(a, b) return a.pos.row < b.pos.row or (a.pos.row == b.pos.row and a.pos.col < b.pos.col) end
  )
  return list
end

-- The region at `at` ({row, col}, 0-based), else the nearest one.
local function region_at(at)
  local best, best_dist
  for _, item in ipairs(sorted()) do
    local p = item.pos
    if p.row == at.row and at.col >= p.col and at.col < math.max(p.end_col, p.col + 1) then
      return item.region
    end
    local dist = math.abs(p.row - at.row) * 10000 + math.abs(p.col - at.col)
    if not best_dist or dist < best_dist then
      best, best_dist = item.region, dist
    end
  end
  return best
end

local function cursor()
  local c = api.nvim_win_get_cursor(0)
  return { row = c[1] - 1, col = c[2] }
end

local function set_cursor(row, col) api.nvim_win_set_cursor(0, { row + 1, col }) end

-- Remember where an edit starts: the cursor, the region it's on, and where
-- that region is before the edit moves it. The replay offset comes from these.
local function capture()
  state.pre = cursor()
  state.main = region_at(state.pre)
  state.main_pos = state.main and pos(state.main)
end

-- Next match of the selection pattern after (or before) `from`, skipping
-- matches that are already selected. Returns row, col or nil.
local function find(from, backward)
  local view = vim.fn.winsaveview()
  set_cursor(from.row, from.col)
  local flags = backward and "bw" or "w"
  local found
  for _ = 1, #state.regions + 1 do
    local m = vim.fn.searchpos(state.pattern, flags)
    if m[1] == 0 then
      break
    end
    local row, col = m[1] - 1, m[2] - 1
    local taken = false
    for _, item in ipairs(sorted()) do
      if item.pos.row == row and item.pos.col == col then
        taken = true
      end
    end
    if not taken then
      found = { row = row, col = col }
      break
    end
  end
  vim.fn.winrestview(view)
  return found
end

local function add_match(backward)
  if not state.pattern then
    vim.notify("multicursor: no pattern (started from lines)", vim.log.levels.INFO)
    return
  end
  local match = find(cursor(), backward)
  if not match then
    vim.notify("multicursor: no more matches", vim.log.levels.INFO)
    return
  end
  add_region(match.row, match.col, match.col + state.length, "selection")
  set_cursor(match.row, match.col)
end

function M._add_match(backward) add_match(backward) end

-- Runs `run` at every region other than the one the last command started on,
-- at the same offset from each, then turns every region into a cursor where it
-- ended up (merging any that landed together).
local function repeat_at_others(run)
  state.replaying = true
  local pre = state.pre
  local main = state.main
  if not main or not vim.tbl_contains(state.regions, main) then
    main = region_at(pre)
    state.main_pos = pos(main)
  end
  local main_pos = state.main_pos
  local drow, dcol = pre.row - main_pos.row, pre.col - main_pos.col
  local after_main = cursor()
  local view = vim.fn.winsaveview()

  local targets = {}
  for _, item in ipairs(sorted()) do
    if item.region ~= main then
      table.insert(targets, item)
    end
  end
  -- Where each run leaves its cursor, as extmarks so later runs on the same
  -- line shift them correctly.
  local marks = { api.nvim_buf_set_extmark(state.buf, ns_tmp, after_main.row, after_main.col, {}) }
  -- Bottom-up, so earlier runs never shift later targets' rows.
  for i = #targets, 1, -1 do
    local p = pos(targets[i].region)
    local row = p.row + drow
    local col = drow == 0 and p.col + dcol or pre.col
    if row >= 0 and row < api.nvim_buf_line_count(state.buf) then
      local line = api.nvim_buf_get_lines(state.buf, row, row + 1, true)[1]
      set_cursor(row, math.max(0, math.min(col, math.max(#line - 1, 0))))
      run()
      local c = cursor()
      table.insert(marks, api.nvim_buf_set_extmark(state.buf, ns_tmp, c.row, c.col, {}))
    end
  end

  for _, r in ipairs(vim.list_extend({}, state.regions)) do
    remove_region(r)
  end
  state.pattern = nil
  local seen = {}
  for _, id in ipairs(marks) do
    local m = api.nvim_buf_get_extmark_by_id(state.buf, ns_tmp, id, {})
    local key = m[1] .. ":" .. m[2]
    if not seen[key] then
      seen[key] = true
      add_region(m[1], m[2], nil, "cursor")
    end
  end
  api.nvim_buf_clear_namespace(state.buf, ns_tmp, 0, -1)
  vim.fn.winrestview(view)
  local main_mark = pos(state.regions[1])
  set_cursor(main_mark.row, main_mark.col)
  capture()
  state.keys = ""
  state.tick = api.nvim_buf_get_changedtick(state.buf)
  state.frozen = false
  state.replaying = false
end

-- Repeat the change just made at the other regions with `.`; one undo step.
local function replay()
  if not state or state.replaying or api.nvim_buf_get_changedtick(state.buf) == state.tick then
    return
  end
  repeat_at_others(function()
    pcall(vim.cmd, "undojoin")
    vim.cmd("silent! normal! .")
  end)
end

-- Run the keys of the motion just made at the other regions.
local function replay_motion()
  local keys = state.keys
  state.keys = ""
  repeat_at_others(function() vim.cmd("silent! keepjumps normal! " .. keys) end)
end

local function has_selections()
  for _, r in ipairs(state.regions) do
    if r.kind == "selection" then
      return true
    end
  end
  return false
end

-- c/d/i/a on selections: move to the selection under the cursor, then start
-- the matching edit so `.` repeats it the same way everywhere. Expr mappings
-- that return keys, so the edit lands before anything typed after it.
function M._prepare(key)
  local p = pos(region_at(cursor()))
  set_cursor(p.row, key == "a" and p.end_col - 1 or p.col)
  capture()
  state.frozen = true
end

local function selection_edit(key)
  return function()
    if not has_selections() then
      return key
    end
    local keys = key
    if key == "c" or key == "d" then
      -- Select the match's characters; `.` then repeats on that many.
      local p = pos(region_at(cursor()))
      local text = api.nvim_buf_get_text(state.buf, p.row, p.col, p.row, p.end_col, {})[1]
      local n = vim.fn.strchars(text)
      keys = "v" .. (n > 1 and (n - 1) .. "l" or "") .. key
    end
    return ("<Cmd>lua require('mvim.multicursor')._prepare(%q)<CR>%s"):format(key, keys)
  end
end

local function goto_region(step)
  local list = sorted()
  local here = region_at(cursor())
  for i, item in ipairs(list) do
    if item.region == here then
      local target = list[(i - 1 + step) % #list + 1].pos
      set_cursor(target.row, target.col)
      return
    end
  end
end

function M.stop()
  if not state then
    return
  end
  api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, lhs in ipairs(state.maps) do
    pcall(vim.keymap.del, lhs[1], lhs[2], { buffer = state.buf })
  end
  api.nvim_del_augroup_by_id(state.group)
  vim.on_key(nil, ns_keys)
  state = nil
end

local function add_cursor_vertical(step)
  local c = cursor()
  local row = c.row + step
  if row < 0 or row >= api.nvim_buf_line_count(0) then
    return
  end
  if state and state.pattern then
    vim.notify("multicursor: can't mix selections and cursors", vim.log.levels.INFO)
    return
  end
  if not state then
    M.start()
    add_region(c.row, c.col, nil, "cursor")
  end
  -- Same screen column on the new line (tabs and wide characters differ).
  local col = math.max(vim.fn.virtcol2col(0, row + 1, vim.fn.virtcol(".")) - 1, 0)
  add_region(row, col, nil, "cursor")
  set_cursor(row, col)
  capture()
end

function M.start()
  if state then
    return
  end
  local buf = api.nvim_get_current_buf()
  state = {
    buf = buf,
    regions = {},
    maps = {},
    tick = api.nvim_buf_get_changedtick(buf),
    group = api.nvim_create_augroup("mvim_multicursor", {}),
    keys = "", -- normal-mode keys typed since the last command, for motions
    own_keys = {},
  }
  capture()

  -- Record typed keys in normal mode; a finished motion replays them. Our own
  -- mappings clear them, and so does leaving normal mode (operators, insert,
  -- visual, the command line), since those are edits or not replayable.
  -- Neovim reports a key after resolving its mapping, so keys of this module's
  -- own mappings are skipped here rather than cleared by them. n/N count as
  -- motions once there's no match pattern (they search then).
  vim.on_key(function(_, typed)
    if
      not state
      or state.replaying
      or not typed
      or typed == ""
      or api.nvim_get_current_buf() ~= state.buf
      or api.nvim_get_mode().mode ~= "n"
    then
      return
    end
    local own = state.own_keys[typed]
    if own and not ((typed == "n" or typed == "N") and not state.pattern) then
      return
    end
    state.keys = state.keys .. typed
  end, ns_keys)

  local function map(lhs, fn, expr)
    local wrapped = expr and fn or function()
      state.keys = ""
      return fn()
    end
    vim.keymap.set("n", lhs, wrapped, { buffer = buf, nowait = true, expr = expr })
    table.insert(state.maps, { "n", lhs })
    state.own_keys[vim.keycode(lhs)] = true
  end
  map("<C-n>", function() add_match(false) end)
  map("n", function()
    if not state.pattern then
      return "n"
    end
    state.keys = ""
    return "<Cmd>lua require('mvim.multicursor')._add_match(false)<CR>"
  end, true)
  map("N", function()
    if not state.pattern then
      return "N"
    end
    state.keys = ""
    return "<Cmd>lua require('mvim.multicursor')._add_match(true)<CR>"
  end, true)
  map("q", function()
    local here = region_at(cursor())
    local count = #state.regions
    add_match(false)
    if #state.regions > count then
      remove_region(here)
    end
  end)
  map("Q", function()
    remove_region(region_at(cursor()))
    if #state.regions == 0 then
      M.stop()
    else
      goto_region(0)
    end
  end)
  map("]", function() goto_region(1) end)
  map("[", function() goto_region(-1) end)
  map("<C-Down>", function() add_cursor_vertical(1) end)
  map("<C-Up>", function() add_cursor_vertical(-1) end)
  map("<Esc>", function()
    M.stop()
    vim.cmd("nohlsearch")
  end)
  for _, key in ipairs({ "c", "d", "i", "a" }) do
    map(key, selection_edit(key), true)
  end
  -- Undo/redo aren't changes to replay.
  for _, key in ipairs({ "u", "<C-r>" }) do
    map(key, function()
      vim.cmd(key == "u" and "silent! undo" or "silent! redo")
      state.tick = api.nvim_buf_get_changedtick(buf)
    end)
  end

  -- `pre` is where the cursor was when the edit began: the offset replayed at
  -- the other cursors. Once normal mode is left (operator, visual, insert) it
  -- stays put until the edit is replayed, so the cursor stepping back on <Esc>
  -- doesn't count. Leaving and returning without a change releases it.
  api.nvim_create_autocmd("CursorMoved", {
    group = state.group,
    buffer = buf,
    callback = function()
      if not state or state.replaying or state.frozen or api.nvim_get_mode().mode ~= "n" then
        return
      end
      if api.nvim_buf_get_changedtick(buf) ~= state.tick then
        return -- a change (like x) moved the cursor; its replay comes next
      end
      if state.keys ~= "" then
        replay_motion()
      else
        capture()
      end
    end,
  })
  api.nvim_create_autocmd("ModeChanged", {
    group = state.group,
    buffer = buf,
    callback = function()
      if not state or state.replaying then
        return
      end
      local old, new = vim.v.event.old_mode, vim.v.event.new_mode
      if old == "n" and new ~= "n" then
        state.frozen = true
        state.keys = ""
      elseif new == "n" and api.nvim_buf_get_changedtick(buf) == state.tick then
        state.frozen = false
      end
    end,
  })
  -- Normal-mode changes end with TextChanged; insert-mode ones with InsertLeave.
  api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = state.group,
    buffer = buf,
    callback = function() vim.schedule(replay) end,
  })
  api.nvim_create_autocmd("BufLeave", { group = state.group, buffer = buf, callback = M.stop })
end

-- <C-n> in normal mode: select the word under the cursor, or add the next one.
function M.word()
  if state then
    return add_match(false)
  end
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  local c = cursor()
  local line = api.nvim_get_current_line()
  local pattern = [[\V\C\<]] .. vim.fn.escape(word, [[\]]) .. [[\>]]
  -- Find the occurrence under (or after) the cursor on this line.
  local start = 0
  local col
  while true do
    local m = vim.fn.matchstrpos(line, pattern, start)
    if m[2] < 0 then
      break
    end
    col = m[2]
    if m[3] > c.col then
      break
    end
    start = m[3]
  end
  if not col then
    return
  end
  M.start()
  state.pattern, state.length = pattern, #word
  add_region(c.row, col, col + #word, "selection")
  set_cursor(c.row, col)
  capture()
end

-- <C-n> in visual mode.
function M.visual()
  local mode = vim.fn.mode()
  local v, dot = vim.fn.getpos("v"), vim.fn.getpos(".")
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  local srow, erow = math.min(v[2], dot[2]) - 1, math.max(v[2], dot[2]) - 1

  if mode == "v" then
    if srow ~= erow then
      vim.notify("multicursor: select text on one line", vim.log.levels.INFO)
      return
    end
    local scol, ecol = math.min(v[3], dot[3]) - 1, math.max(v[3], dot[3])
    local text = api.nvim_buf_get_text(0, srow, scol, srow, ecol, {})[1]
    if state then
      M.stop()
    end
    M.start()
    state.pattern, state.length = [[\V\C]] .. vim.fn.escape(text, [[\]]), #text
    add_region(srow, scol, ecol, "selection")
    set_cursor(srow, scol)
    capture()
    return
  end

  -- Linewise or blockwise: a column of cursors.
  local vcol = mode == "V" and vim.fn.virtcol({ dot[2], dot[3] })
    or math.min(vim.fn.virtcol({ v[2], v[3] }), vim.fn.virtcol({ dot[2], dot[3] }))
  if state then
    M.stop()
  end
  M.start()
  for row = srow, erow do
    local col = vim.fn.virtcol2col(0, row + 1, vcol) - 1
    add_region(row, math.max(col, 0), nil, "cursor")
  end
  local here = dot[2] - 1
  set_cursor(here, math.max(vim.fn.virtcol2col(0, here + 1, vcol) - 1, 0))
  capture()
end

function M.setup()
  api.nvim_set_hl(0, "MvimSelection", { link = "Visual", default = true })
  api.nvim_set_hl(0, "MvimCursor", { link = "Cursor", default = true })
  vim.keymap.set("n", "<C-n>", M.word, { desc = "Multicursor: word under cursor / next match" })
  vim.keymap.set("x", "<C-n>", M.visual, { desc = "Multicursor: selected text, or cursors on selected lines" })
  vim.keymap.set("n", "<C-Down>", function() add_cursor_vertical(1) end, { desc = "Multicursor: add cursor below" })
  vim.keymap.set("n", "<C-Up>", function() add_cursor_vertical(-1) end, { desc = "Multicursor: add cursor above" })
end

return M
