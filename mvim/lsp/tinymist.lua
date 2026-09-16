return {
  cmd = { "tinymist" },
  filetypes = { "typst" },
  offset_encoding = "utf-8",
  -- Project root is the git repo, or the file's directory outside one.
  root_dir = function(bufnr, on_dir)
    on_dir(vim.fs.root(bufnr, { ".git" }) or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
  settings = {
    exportPdf = "onSave",
  },
}
