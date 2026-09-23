-- <leader>f: trim trailing whitespace, then pipe the buffer through each
-- formatter for its filetype that is on PATH, in order. If none are available,
-- fall back to LSP formatting. Formatters come from the devshell, not mvim.
local M = {}

-- Each entry is a function of the file path returning argv; stdin is the
-- buffer and stdout replaces it.
local prettierd = { function(path) return { "prettierd", path } end }

local formatters = {
  css = prettierd,
  elixir = { function() return { "mix", "format", "-" } end },
  go = {
    function() return { "goimports" } end,
    function() return { "gofmt" } end,
  },
  html = prettierd,
  javascript = prettierd,
  javascriptreact = prettierd,
  json = prettierd,
  jsonc = prettierd,
  lua = { function(path) return { "stylua", "--stdin-filepath", path, "-" } end },
  nix = { function() return { "alejandra", "--quiet", "-" } end },
  python = {
    function(path) return { "isort", "--filename", path, "-" } end,
    function(path) return { "ruff", "format", "--stdin-filename", path, "-" } end,
  },
  rust = { function() return { "rustfmt", "--emit=stdout" } end },
  scss = prettierd,
  sh = { function() return { "shfmt", "-" } end },
  toml = { function() return { "taplo", "format", "-" } end },
  typescript = prettierd,
  typescriptreact = prettierd,
  typst = { function() return { "typstyle" } end },
  yaml = prettierd,
}

local function trim_whitespace()
  local view = vim.fn.winsaveview()
  vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
  vim.fn.winrestview(view)
end

function M.format()
  trim_whitespace()

  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fs.dirname(path)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local text = table.concat(lines, "\n") .. "\n"
  local ran = false

  for _, argv_for in ipairs(formatters[vim.bo[buf].filetype] or {}) do
    local argv = argv_for(path)
    if vim.fn.executable(argv[1]) == 1 then
      ran = true
      local result = vim.system(argv, { stdin = text, cwd = cwd, text = true }):wait(5000)
      if result.code == 0 and result.stdout and result.stdout ~= "" then
        text = result.stdout
      else
        vim.notify(("%s failed: %s"):format(argv[1], vim.trim(result.stderr or "")), vim.log.levels.WARN)
      end
    end
  end

  if not ran then
    if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0 then
      vim.lsp.buf.format({ async = true })
    end
    return
  end

  local new = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
  if not vim.deep_equal(new, lines) then
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, new)
    vim.fn.winrestview(view)
  end
end

function M.setup() vim.keymap.set("n", "<leader>f", M.format) end

return M
