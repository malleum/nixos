-- LSP keys shared by mvim and the full nixvim build (nixvim/default.nix
-- inlines this file). Both use neovim's defaults and only add keys that don't
-- shadow one; `:help lsp-defaults` lists them, `:nmap gr` shows what is bound.
--
--   grn rename          gra code action      grr references (quickfix)
--   gri implementation  grt type definition  grx run code lens
--   gO  document symbols  <C-s> signature help (insert)
--   <C-]> definition (<C-t> back; g<C-]> lists several)
--   [d ]d prev/next diagnostic  [D ]D first/last  <C-w>d diagnostic float
--   an / in  grow / shrink selection by syntax node  [N ]N siblings
--
-- Added here:
--   K    hover, and nothing when no server is attached (see below)
--   gd   definition, in LSP buffers only (<C-]> is awkward on Dvorak). Jumps
--        when there is one result (<C-t> back), quickfix when several. Buffers
--        without LSP keep vim's own gd.
--   grc  callers, only from files under the working directory, so call sites
--        in tests or scripts elsewhere stay out of the way
--   grC  all callers
-- grc/grC jump straight to a single caller, otherwise list them (Telescope
-- when available, else quickfix). Servers without call hierarchy (nixd,
-- lua_ls) fall back to references, filtered the same way.

-- K is hover, and only hover: without a language server it says so instead of
-- opening vim's keywordprg window (:help or a man page), which never had the
-- documentation being looked for and hid that no server was running.
vim.keymap.set(
  "n",
  "K",
  function() vim.notify("No language server attached (:Direnv loads a devshell's)", vim.log.levels.WARN) end,
  { desc = "Hover (LSP only)" }
)

local CALLS = "textDocument/prepareCallHierarchy"

local function has_telescope()
  local ok, builtin = pcall(require, "telescope.builtin")
  return ok and builtin or nil
end

local function under_cwd(items)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  return vim.tbl_filter(function(item) return vim.fs.relpath(cwd, vim.fs.normalize(item.filename)) ~= nil end, items)
end

local function show(title, items, total)
  if #items == 0 then
    local hint = total > 0 and (" (%d outside %s; grC for all)"):format(total, vim.fn.getcwd()) or ""
    vim.notify(("%s: none%s"):format(title, hint), vim.log.levels.INFO)
    return
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })
  if #items == 1 then
    -- Record the jump like vim.lsp.buf.definition() does, so <C-t> returns.
    local from = vim.fn.getpos(".")
    from[1] = vim.api.nvim_get_current_buf()
    local tag = { tagname = vim.fn.expand("<cword>"), from = from }
    vim.fn.settagstack(vim.fn.win_getid(), { items = { tag } }, "t")
    vim.cmd("silent cfirst")
    return
  end
  local telescope = has_telescope()
  if telescope then
    telescope.quickfix({ prompt_title = title })
  else
    vim.cmd("botright copen")
  end
end

-- Callers of the symbol under the cursor, as quickfix items at each call site.
local function incoming_calls(on_items)
  local client = vim.lsp.get_clients({ bufnr = 0, method = CALLS })[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request(CALLS, params, function(err, result)
    if err or not result or #result == 0 then
      vim.notify("No call hierarchy item under the cursor", vim.log.levels.WARN)
      return
    end
    client:request("callHierarchy/incomingCalls", { item = result[1] }, function(err2, calls)
      if err2 then
        vim.notify(err2.message, vim.log.levels.WARN)
        return
      end
      local items = {}
      for _, call in ipairs(calls or {}) do
        local ranges = #call.fromRanges > 0 and call.fromRanges or { call.from.selectionRange }
        local locations = vim.tbl_map(function(range) return { uri = call.from.uri, range = range } end, ranges)
        for _, item in ipairs(vim.lsp.util.locations_to_items(locations, client.offset_encoding)) do
          item.text = call.from.name .. ": " .. vim.trim(item.text)
          table.insert(items, item)
        end
      end
      on_items(items)
    end)
  end)
end

local function references(on_items)
  vim.lsp.buf.references(nil, { on_list = function(list) on_items(list.items) end })
end

local function callers(only_cwd)
  local supported = #vim.lsp.get_clients({ bufnr = 0, method = CALLS }) > 0
  local title = supported and "Callers" or "References"
  if only_cwd then
    title = title .. " in " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  end
  local fetch = supported and incoming_calls or references
  fetch(vim.schedule_wrap(function(items)
    local shown = only_cwd and under_cwd(items) or items
    show(title, shown, #items)
  end))
end

vim.keymap.set("n", "grc", function() callers(true) end, { desc = "Callers under the working directory" })
vim.keymap.set("n", "grC", function() callers(false) end, { desc = "All callers" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("mvim_lsp_keys", {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/definition") then
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "LSP definition" })
    end
    -- neovim only maps its default K when nothing else has; ours above counts.
    if client and client:supports_method("textDocument/hover") then
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = args.buf, desc = "LSP hover" })
    end
  end,
})
