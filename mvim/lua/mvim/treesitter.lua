-- Starts treesitter highlighting for every filetype with a parser on the
-- runtimepath: neovim's bundled ones plus the grammars and nvim-treesitter
-- queries packaged in modules/meta/nvim.nix.

-- Filetypes whose name differs from their parser's.
vim.treesitter.language.register("bash", { "sh" })
vim.treesitter.language.register("eex", { "eelixir" })
vim.treesitter.language.register("git_rebase", { "gitrebase" })
vim.treesitter.language.register("javascript", { "javascriptreact" })
vim.treesitter.language.register("json", { "jsonc" })
vim.treesitter.language.register("tsx", { "typescriptreact" })

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and vim.treesitter.language.add(lang) then
      pcall(vim.treesitter.start, args.buf, lang)
    end
  end,
})
