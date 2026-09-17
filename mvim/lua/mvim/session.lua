-- Per-directory sessions, saved automatically on exit and restored on demand.
-- The command is named after auto-session's so tmux-resurrect's restore entry
-- (`nvim -c "AutoSession restore"`, modules/programs/tmux.nix) works with
-- either nvim build.
--   :AutoSession save | restore | delete
local M = {}

local function session_file()
  local dir = vim.fn.stdpath("state") .. "/sessions"
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. vim.uv.cwd():gsub("/", "%%") .. ".vim"
end

-- Sessions untouched for 30 days are deleted, so ones for directories you
-- no longer work in don't pile up.
local max_age = 30 * 24 * 60 * 60

local function prune()
  local dir = vim.fn.stdpath("state") .. "/sessions"
  local now = os.time()
  for name, type in vim.fs.dir(dir) do
    local path = dir .. "/" .. name
    local stat = type == "file" and vim.uv.fs_stat(path)
    if stat and now - stat.mtime.sec > max_age then
      os.remove(path)
    end
  end
end

-- Only save when a real file is open, so `nvim` + `:q` doesn't clobber a session.
local function has_files()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
      return true
    end
  end
  return false
end

local actions = {
  save = function() vim.cmd("mksession! " .. vim.fn.fnameescape(session_file())) end,
  restore = function()
    local file = session_file()
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("silent! source " .. vim.fn.fnameescape(file))
    end
  end,
  delete = function() os.remove(session_file()) end,
}

function M.setup()
  vim.api.nvim_create_user_command("AutoSession", function(opts)
    local action = actions[opts.args]
    if not action then
      vim.notify("AutoSession: expected save, restore or delete", vim.log.levels.ERROR)
      return
    end
    action()
  end, {
    nargs = 1,
    complete = function() return vim.tbl_keys(actions) end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if has_files() then
        actions.save()
      end
      prune()
    end,
  })
end

return M
