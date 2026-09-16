-- Servers are configured in ../../lsp/<name>.lua and enabled only when their
-- binary is on PATH, so a devshell decides which ones run. Nothing is bundled.
local servers = {
  "bashls",
  "clangd",
  "cssls",
  "elixirls",
  "gopls",
  "html",
  "jdtls",
  "jsonls",
  "ltex_plus",
  "lua_ls",
  "marksman",
  "nixd",
  "rust_analyzer",
  "sqls",
  "taplo",
  "tinymist",
  "ts_ls",
  "ty",
  "yamlls",
  "zls",
}

for _, name in ipairs(servers) do
  local cmd = vim.lsp.config[name].cmd
  if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(name)
  end
end

vim.lsp.inlay_hint.enable(true)

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
