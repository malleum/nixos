-- Starts treesitter highlighting for every filetype with a parser on the
-- runtimepath: neovim's bundled ones plus the grammars and nvim-treesitter
-- queries packaged in modules/meta/nvim.nix.
--
-- It starts just after the file is first drawn (with regex syntax), because
-- compiling a large language's queries takes a while (TypeScript and Rust are
-- over 100 ms) and would otherwise hold up showing the file at all.

local registered = false

local function start(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not registered then
    registered = true
    -- Filetypes whose name differs from their parser's.
    vim.treesitter.language.register("bash", { "sh" })
    vim.treesitter.language.register("eex", { "eelixir" })
    vim.treesitter.language.register("git_rebase", { "gitrebase" })
    vim.treesitter.language.register("javascript", { "javascriptreact" })
    vim.treesitter.language.register("json", { "jsonc" })
    vim.treesitter.language.register("tsx", { "typescriptreact" })
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if lang and vim.treesitter.language.add(lang) then
    pcall(vim.treesitter.start, buf, lang)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    vim.defer_fn(function() start(args.buf) end, 0)
  end,
})
