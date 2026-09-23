-- Runtime directories contributed by a dev shell, named in $MVIM_RTP (a
-- colon-separated list, like $PATH). mvim bundles no plugins and its own
-- runtimepath is baked into the wrapper, so this is how a project that has
-- editor support to offer -- a grammar, a language server, a plugin -- gets it
-- in front of mvim without every host carrying it.
--
-- The directory is shaped like any other vim plugin: lua/, plugin/, ftplugin/,
-- queries/, parser/, lsp/. It is appended rather than prepended, so a dev shell
-- can add to mvim but never shadow it.
--
-- Loaded at startup for a shell that was already active, and again after
-- :Direnv (User MvimEnvChanged) for one loaded since. This module's autocommand
-- is registered before lsp.lua's, so a shell's lsp/<name>.lua is on the
-- runtimepath by the time servers are enabled.
local M = {}

local loaded = {}

function M.load()
  local added = false
  for dir in (vim.env.MVIM_RTP or ""):gmatch("[^:]+") do
    if not loaded[dir] and vim.uv.fs_stat(dir) then
      loaded[dir] = true
      added = true
      vim.opt.runtimepath:append(dir)
      -- plugin/ is sourced automatically only for directories that were on the
      -- runtimepath at startup, which these never are.
      for _, file in ipairs(vim.fn.glob(dir .. "/plugin/*.lua", false, true)) do
        local ok, err = pcall(vim.cmd.source, file)
        if not ok then
          vim.notify("MVIM_RTP: " .. file .. ":\n" .. err, vim.log.levels.ERROR)
        end
      end
    end
  end
  if added then
    -- Buffers opened before the directory arrived were typed without it: a
    -- filetype the shell's plugin registers was unknown then, so re-detect
    -- rather than replay. Detection fires FileType where it changes anything,
    -- which is what loads the ftplugin and starts treesitter (treesitter.lua).
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        vim.api.nvim_buf_call(buf, function() vim.cmd("filetype detect") end)
      end
    end
    -- And once more for buffers whose filetype was already right, which
    -- detection leaves alone: a shell adding only a grammar or an ftplugin for
    -- a language mvim already knows has nothing to re-detect.
    vim.cmd("doautoall FileType")
  end
end

function M.setup()
  M.load()
  vim.api.nvim_create_autocmd("User", { pattern = "MvimEnvChanged", callback = M.load })
end

return M
