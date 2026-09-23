-- :Direnv loads direnv's environment for the working directory into neovim,
-- like direnv.vim but only when asked. neovim keeps the environment it was
-- started with, so a dev shell allowed or built after starting (devinit,
-- `direnv allow`, a :cd into another project) is otherwise never seen.
-- Deliberately not automatic: a large flake's shell can take minutes to build,
-- and opening mvim shouldn't restart a build that was interrupted on purpose.
-- It runs in the background; afterwards the User MvimEnvChanged event lets
-- lsp.lua start newly available servers.
local M = {}

local running = false

function M.load()
  if vim.fn.executable("direnv") == 0 then
    return vim.notify("direnv is not installed", vim.log.levels.WARN)
  end
  if running then
    return vim.notify("direnv: already loading", vim.log.levels.INFO)
  end
  running = true
  vim.notify("direnv: loading...", vim.log.levels.INFO)
  vim.system({ "direnv", "export", "json" }, { cwd = vim.fn.getcwd(), text = true }, function(result)
    vim.schedule(function()
      running = false
      if result.code ~= 0 then
        local err = vim.trim(result.stderr or "")
        if err:find("is blocked", 1, true) then
          return vim.notify("direnv: .envrc is blocked; run `direnv allow`", vim.log.levels.WARN)
        end
        return vim.notify("direnv failed:\n" .. err, vim.log.levels.ERROR)
      end
      local out = vim.trim(result.stdout or "")
      local ok, env = pcall(vim.json.decode, out ~= "" and out or "{}")
      if not ok or type(env) ~= "table" or vim.tbl_isempty(env) then
        return vim.notify("direnv: environment already up to date", vim.log.levels.INFO)
      end
      for name, value in pairs(env) do
        vim.env[name] = value ~= vim.NIL and value or nil
      end
      vim.api.nvim_exec_autocmds("User", { pattern = "MvimEnvChanged" })
      vim.notify("direnv: environment loaded", vim.log.levels.INFO)
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("Direnv", M.load, { desc = "Load direnv's environment for the working directory" })
end

return M
