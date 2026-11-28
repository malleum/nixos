-- The completion menu's look and the docs float beside it.

test("convert: icon, name and the result type on the right", function(c)
  local got = c:lua([[
    local convert = require("mvim.completion").convert
    return {
      convert({ label = "sum", kind = 3, detail = "sum(list int) → int", labelDetails = { description = "int" } }),
      convert({ label = "map", kind = 3, detail = "map{…} → seq (int, int)" }),
      convert({ label = "foo", kind = 6, detail = "fn foo(a: i32) -> Vec<String>" }),
      convert({ label = "n", kind = 6, detail = "dict (int, int) (list (str, int, bool))" }),
    }]])
  eq({ abbr = "sum", kind = "\u{f0295} ", kind_hlgroup = "MvimKindFunction", menu = "int" }, got[1])
  eq("seq (int, int)", got[2].menu)
  eq("Vec<String>", got[3].menu)
  eq("dict (int, int) (list (str, i…", got[4].menu, "cut to 30 columns")
  eq("MvimKindVariable", got[4].kind_hlgroup)
end)

test("the menu has a border and the kinds first", function(c)
  eq(
    { "rounded", "kind,abbr,menu", "menuone,noselect,noinsert,fuzzy" },
    c:lua("return { vim.o.pumborder, vim.o.completeitemalign, vim.o.completeopt }")
  )
  eq(true, c:lua("return vim.fn.hlexists('MvimKindFunction') == 1"))
end)

-- A headless test has no UI, so nvim draws no menu and sends no
-- CompleteChanged. These call the handler with the event a menu would send,
-- and tell the module the menu is open.
local setup = [[
  local m = require("mvim.completion")
  m.menu_open = function() return true end
  _G.event = function(item, box)
    return vim.tbl_extend("force", { row = 3, col = 10, width = 16, height = 4, scrollbar = false }, box or {}, {
      completed_item = item and { word = item.label, user_data = { nvim = { lsp = { completion_item = item } } } } or {},
    })
  end
  _G.sum = { label = "sum", documentation = { kind = "markdown",
    value = "```lua\nsum(xs)\n```\n\nThe total.\n\n*e.g.*\n```lua\nsum({ 1, 2 })\n```" } }
]]

local list_floats = [[
  local out = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(w)
    if cfg.relative ~= "" then
      out[#out + 1] = { border = cfg.border[1], row = cfg.row, col = cfg.col, width = cfg.width,
        height = cfg.height, lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, true) }
    end
  end
  return out]]

-- The floats, once the handler's scheduled drawing has run.
local function floats(c)
  c:settle(30)
  return c:lua(list_floats)
end

test("docs float: right of the menu's border, with the docs as markdown", function(c)
  c:lua(setup)
  c:lua("require('mvim.completion').on_changed(event(sum))")
  local f = floats(c)
  eq(1, #f)
  eq({ "```lua", "sum(xs)", "```", "", "The total.", "", "*e.g.*", "```lua", "sum({ 1, 2 })", "```" }, f[1].lines)
  eq({ "╭", 3, 28 }, { f[1].border, f[1].row, f[1].col }, "the menu's border is column 27")
  eq("markdown", c:lua("return vim.bo[vim.api.nvim_win_get_buf(vim.api.nvim_list_wins()[2])].filetype"))
end)

test("docs float: left of the menu when the right has no room", function(c)
  c:lua(setup)
  c:lua("require('mvim.completion').on_changed(event(sum, { col = vim.o.columns - 20 }))")
  local f = floats(c)
  local cols = c:lua("return vim.o.columns")
  eq(cols - 20 - 2, f[1].col + f[1].width + 1, "its right border just left of the menu's, at col - 1")
end)

test("docs float: the detail on top when the docs have no code", function(c)
  c:lua(setup)
  c:lua([[require('mvim.completion').on_changed(event({ label = "len", detail = "fn len(&self) -> usize",
    documentation = "Returns the *length*." }))]])
  local f = floats(c)
  eq({ "```" .. c:lua("return vim.bo.filetype"), "fn len(&self) -> usize", "```", "", "Returns the \\*length\\*." }, f[1].lines)
end)

test("docs float: none for an item without docs, and closed with the menu", function(c)
  c:lua(setup)
  c:lua("require('mvim.completion').on_changed(event(sum))")
  eq(1, #floats(c))
  c:lua("require('mvim.completion').on_changed(event({ label = 'nodoc' }))")
  eq({}, floats(c), "an item with nothing to show, and no server to ask")
  c:lua("require('mvim.completion').on_changed(event(sum))")
  eq(1, #floats(c))
  c:lua("vim.api.nvim_exec_autocmds('CompleteDone', {})")
  eq({}, floats(c))
  c:lua("require('mvim.completion').on_changed(event(sum))")
  c:lua("vim.api.nvim_exec_autocmds('InsertLeave', {})")
  eq({}, floats(c))
end)

test("docs float: a selection that moves on drops the old docs", function(c)
  c:lua(setup)
  -- Two changes before the float is drawn: only the last item's docs show.
  c:lua([[
    local m = require('mvim.completion')
    m.on_changed(event(sum))
    m.on_changed(event({ label = "max", documentation = "The largest." }))]])
  local f = floats(c)
  eq(1, #f)
  eq({ "The largest." }, f[1].lines)
end)

test("CompleteChanged reaches the handler", function(c)
  eq(1, c:lua("return #vim.api.nvim_get_autocmds({ group = 'mvim.completion', event = 'CompleteChanged' })"))
end)
