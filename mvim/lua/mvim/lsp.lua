-- Servers are configured in ../../lsp/<name>.lua -- every file there is one,
-- and so is every lsp/<name>.lua a dev shell puts on the runtimepath (see
-- shellrtp.lua). Each is enabled only when its binary is on PATH, so a devshell
-- decides which ones run. Nothing is bundled. Both the runtimepath and PATH are
-- looked at again after :Direnv loads a dev shell's environment (see
-- direnv.lua), so its servers start without restarting mvim.
local function configured()
  local names = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
    names[#names + 1] = vim.fn.fnamemodify(path, ":t:r")
  end
  return names
end

local function enable_available()
  for _, name in ipairs(configured()) do
    local cmd = vim.lsp.config[name].cmd
    if not vim.lsp.is_enabled(name) and type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
      vim.lsp.enable(name) -- also attaches to matching buffers already open
    end
  end
end

-- Loading vim.lsp and every server config takes about 10 ms, so it happens
-- right after startup instead of before the first screen. Files opened at
-- startup still get their servers: vim.lsp.enable attaches to open buffers.
local function setup()
  enable_available()
  -- Diagnostic messages appear as lines under the cursor's line only; other
  -- lines keep just their sign.
  vim.diagnostic.config({ virtual_lines = { current_line = true } })
  vim.lsp.inlay_hint.enable(true)
end

if vim.v.vim_did_enter == 1 then
  setup()
else
  vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function() vim.schedule(setup) end })
end
vim.api.nvim_create_autocmd("User", { pattern = "MvimEnvChanged", callback = enable_available })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method("textDocument/completion") then
      -- autotrigger only fires on the server's trigger characters (".", ":"
      -- ...); add word characters so the menu opens while typing, like blink.
      local provider = client.server_capabilities.completionProvider
      local triggers = provider.triggerCharacters or {}
      for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"):gmatch(".") do
        table.insert(triggers, c)
      end
      provider.triggerCharacters = triggers
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

-- <CR> accepts the selected item (or the first one), else falls through to
-- autopairs' newline handling. <C-n>/<C-p> open LSP completion when no menu is
-- showing, and fall back to buffer words where no server is attached.
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.fn.complete_info({ "selected" }).selected == -1 and "<C-n><C-y>" or "<C-y>"
  end
  return require("mvim.autopairs").cr()
end, { expr = true })

for _, key in ipairs({ "<C-n>", "<C-p>" }) do
  vim.keymap.set("i", key, function()
    if vim.fn.pumvisible() == 1 or #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) == 0 then
      return key
    end
    vim.lsp.completion.get()
    return ""
  end, { expr = true })
end
