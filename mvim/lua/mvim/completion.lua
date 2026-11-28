-- How LSP completion looks: a bordered menu of icon, name and a short type,
-- with the server's docs in a bordered float beside it. The menu shows only
-- what tells items apart (kind, name, result type); the full signature, the
-- docs and any example are in the float. Needs 'completeopt' without
-- "popup", which would open nvim's own borderless docs window as well.
local M = {}

-- Nerd Font (Material Design) icons by LSP CompletionItemKind name, written
-- as escapes so no editor or tool can drop them. Each kind's icon takes the
-- colour of the colorscheme's LspKind<name> group where it has one.
local icons = {
  Text = "\u{f0284}", -- nf-md-format_text
  Method = "\u{f01a7}", -- nf-md-cube_outline
  Function = "\u{f0295}", -- nf-md-function
  Constructor = "\u{f0493}", -- nf-md-cog
  Field = "\u{f04fc}", -- nf-md-tag_outline
  Variable = "\u{f0ae7}", -- nf-md-variable
  Class = "\u{f0831}", -- nf-md-shape
  Interface = "\u{f0832}", -- nf-md-shape_outline
  Module = "\u{f03d7}", -- nf-md-package_variant_closed
  Property = "\u{f05b7}", -- nf-md-wrench
  Unit = "\u{f046d}", -- nf-md-ruler
  Value = "\u{f03a0}", -- nf-md-numeric
  Enum = "\u{f027a}", -- nf-md-format_list_bulleted_type
  Keyword = "\u{f0306}", -- nf-md-key
  Snippet = "\u{f0169}", -- nf-md-code_braces
  Color = "\u{f03d8}", -- nf-md-palette
  File = "\u{f09ee}", -- nf-md-file_document_outline
  Reference = "\u{f0339}", -- nf-md-link_variant
  Folder = "\u{f024b}", -- nf-md-folder
  EnumMember = "\u{f0bf7}", -- nf-md-alpha_e_box_outline
  Constant = "\u{f03ff}", -- nf-md-pi
  Struct = "\u{f01a6}", -- nf-md-cube
  Event = "\u{f140b}", -- nf-md-lightning_bolt
  Operator = "\u{f0992}", -- nf-md-plus_minus
  TypeParameter = "\u{f0c24}", -- nf-md-alpha_t_box_outline
}

-- Treesitter groups for kinds the colorscheme has no LspKind group for.
local fallback = {
  Function = "@function",
  Method = "@function.method",
  Variable = "@variable",
  Field = "@variable.member",
  Property = "@property",
  Keyword = "@keyword",
  Class = "@type",
  Struct = "@type",
  Interface = "@type",
  Enum = "@type",
  EnumMember = "@constant",
  Constant = "@constant",
  Module = "@module",
  Constructor = "@constructor",
  Operator = "@operator",
  TypeParameter = "@type",
  Snippet = "@string.special",
  Text = "Comment",
}

local MENU_WIDTH = 30

local function shorten(s)
  s = s:gsub("%s+", " ")
  if vim.fn.strchars(s) <= MENU_WIDTH then return s end
  return vim.fn.strcharpart(s, 0, MENU_WIDTH - 1) .. "…"
end

-- The type on the right: the server's description, else the detail's result
-- (`f(a) → b`, `f :: a -> b`), else the detail as it is.
local function short_type(item)
  local desc = vim.tbl_get(item, "labelDetails", "description")
  if desc and desc ~= "" then return shorten(desc) end
  local detail = item.detail or ""
  local ret = detail:match(" → (.*)$") or detail:match("%) %-> (.*)$") or detail:match("%):%s*(.*)$")
  return shorten(ret or detail)
end

---@param item lsp.CompletionItem
function M.convert(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
  return {
    abbr = item.label,
    kind = (icons[kind] or icons.Text) .. " ",
    kind_hlgroup = "MvimKind" .. kind,
    menu = short_type(item),
  }
end

local function set_highlights()
  local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
  local pmenu, sel = hl("Pmenu"), hl("PmenuSel")
  for kind in pairs(icons) do
    local src = vim.fn.hlexists("LspKind" .. kind) == 1 and "LspKind" .. kind or fallback[kind] or "Pmenu"
    vim.api.nvim_set_hl(0, "MvimKind" .. kind, { fg = hl(src).fg })
  end
  local comment, border = hl("Comment"), hl("FloatBorder")
  vim.api.nvim_set_hl(0, "PmenuExtra", { fg = comment.fg, bg = pmenu.bg, italic = true })
  vim.api.nvim_set_hl(0, "PmenuExtraSel", { fg = comment.fg, bg = sel.bg, italic = true })
  vim.api.nvim_set_hl(0, "PmenuKind", { fg = pmenu.fg, bg = pmenu.bg })
  vim.api.nvim_set_hl(0, "PmenuKindSel", { fg = pmenu.fg, bg = sel.bg })
  vim.api.nvim_set_hl(0, "PmenuBorder", { fg = border.fg, bg = pmenu.bg })
  vim.api.nvim_set_hl(0, "PmenuSel", { bg = sel.bg, bold = true })
end

-- The docs float beside the menu. nvim's own 'completeopt' popup can't take
-- a border, so mvim draws its own: the item's docs as markdown (nvim renders
-- fences with the language's highlighting), asked of the server with
-- completionItem/resolve when the item came without them.
local docs = { win = nil, buf = nil, seq = 0 }

local function close_docs()
  docs.seq = docs.seq + 1
  if docs.win and vim.api.nvim_win_is_valid(docs.win) then vim.api.nvim_win_close(docs.win, true) end
  docs.win = nil
end
M.close_docs = close_docs

-- The item's docs as markdown, with the detail on top when the docs don't
-- already start with code (rust-analyzer's signature, say). Nil when empty.
local function markdown(item, ft)
  local doc = item.documentation
  local text = type(doc) == "table" and doc.value or doc or ""
  if type(doc) == "table" and doc.kind == "plaintext" or type(doc) == "string" then
    text = text:gsub("([\\`*_%[%]<>#])", "\\%1")
  end
  local detail = item.detail or ""
  if detail ~= "" and not vim.startswith(vim.trim(text), "```") and not text:find(detail, 1, true) then
    text = ("```%s\n%s\n```"):format(ft, detail) .. (text ~= "" and "\n\n" .. text or "")
  end
  if vim.trim(text) == "" then return nil end
  return text
end

local function show_docs(text, ev)
  if not docs.buf or not vim.api.nvim_buf_is_valid(docs.buf) then
    docs.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[docs.buf].bufhidden = "hide"
  end
  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(docs.buf, 0, -1, false, lines)
  vim.bo[docs.buf].filetype = "markdown"
  pcall(vim.treesitter.start, docs.buf, "markdown")

  -- Beside the menu: to the right when it fits, else to the left. v:event
  -- gives the menu's text area; a border, and the scrollbar it carries, lie
  -- outside it, and this float's own border is outside `col`.
  local edge = vim.o.pumborder ~= "" and 1 or 0
  local right = ev.col + ev.width + (edge == 1 and 2 or (ev.scrollbar and 1 or 0))
  local left = ev.col - edge - 1 -- the last column this float's border may take
  local room_right, room_left = vim.o.columns - right - 2, left - 1
  local widest = 0
  for _, l in ipairs(lines) do
    widest = math.max(widest, vim.fn.strdisplaywidth(l))
  end
  local on_right = room_right >= math.min(widest, 40) or room_right >= room_left
  local room = on_right and room_right or room_left
  if room < 16 then return close_docs() end -- too narrow to read on either side
  local width = math.min(widest, 64, room)
  local col = on_right and right or left - width - 1
  local config = {
    relative = "editor",
    row = math.max(ev.row - (1 - edge), 0),
    col = col,
    width = width,
    height = 1,
    border = vim.o.pumborder ~= "" and vim.o.pumborder or "rounded",
    style = "minimal",
    focusable = false,
    zindex = 60,
    noautocmd = true,
  }
  if docs.win and vim.api.nvim_win_is_valid(docs.win) then
    config.noautocmd = nil
    vim.api.nvim_win_set_config(docs.win, config)
  else
    docs.win = vim.api.nvim_open_win(docs.buf, false, config)
  end
  local wo = vim.wo[docs.win]
  wo.wrap, wo.linebreak, wo.conceallevel = true, true, 2
  wo.winhighlight = "Normal:Pmenu,FloatBorder:PmenuBorder"
  local height = vim.api.nvim_win_text_height(docs.win, {}).all
  vim.api.nvim_win_set_height(docs.win, math.max(1, math.min(height, vim.o.lines - config.row - 4, 20)))
end

-- Whether the menu is still showing. A field so the tests, which have no UI
-- to draw a menu, can say it is.
function M.menu_open() return vim.fn.pumvisible() == 1 end

-- CompleteChanged: `ev` is v:event (the selected item and the menu's box).
function M.on_changed(ev)
  local entry = ev.completed_item or {}
  local item = vim.tbl_get(entry, "user_data", "nvim", "lsp", "completion_item")
  if not item then return vim.schedule(close_docs) end
  docs.seq = docs.seq + 1
  local seq, ft, buf = docs.seq, vim.bo.filetype, vim.api.nvim_get_current_buf()
  local box = { row = ev.row, col = ev.col, width = ev.width, scrollbar = ev.scrollbar }
  -- CompleteChanged may not change windows (textlock), so the float is
  -- drawn just after, if the selection hasn't moved on.
  local function show(t)
    vim.schedule(function()
      if seq == docs.seq and M.menu_open() then show_docs(t, box) end
    end)
  end
  local text = markdown(item, ft)
  if text then return show(text) end
  local client = vim.lsp.get_client_by_id(vim.tbl_get(entry, "user_data", "nvim", "lsp", "client_id") or -1)
  if not client or not client:supports_method("completionItem/resolve", buf) then
    return vim.schedule(close_docs)
  end
  -- The menu is still open with this item selected when the answer comes.
  client:request("completionItem/resolve", item, function(err, resolved)
    if err or not resolved or seq ~= docs.seq or not M.menu_open() then return end
    local t = markdown(resolved, ft)
    if t then
      show(t)
    else
      vim.schedule(close_docs)
    end
  end, buf)
  -- Until the answer, the last item's docs would be wrong.
  vim.schedule(function()
    if seq == docs.seq and docs.win and vim.api.nvim_win_is_valid(docs.win) then
      vim.api.nvim_win_close(docs.win, true)
      docs.win = nil
    end
  end)
end

function M.setup()
  local o = vim.opt
  o.pumborder = "rounded"
  o.pumheight = 14
  o.pummaxwidth = 60
  o.completeitemalign = "kind,abbr,menu"
  set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })
  local group = vim.api.nvim_create_augroup("mvim.completion", { clear = true })
  vim.api.nvim_create_autocmd("CompleteChanged", {
    group = group,
    callback = function() M.on_changed(vim.v.event) end,
  })
  vim.api.nvim_create_autocmd({ "CompleteDone", "InsertLeave" }, {
    group = group,
    callback = function() vim.schedule(close_docs) end,
  })
end

return M
