-- Sign-column diff against the git index, like gitsigns. The index copy is
-- fetched on read/write/focus; edits are diffed in memory.
--   :GitResetHunk  put the unstaged hunk under the cursor back to its staged
--                  (index) version, in the buffer: :w keeps it, u undoes it
local M = {}

local ns = vim.api.nvim_create_namespace("mvim_gitsigns")
local base = {} -- bufnr -> index contents, or false when untracked/not in git
local timers = {}

local function render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if not base[buf] then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local current = table.concat(lines, "\n") .. "\n"
  local hunks = vim.text.diff(base[buf], current, { result_type = "indices" })
  local count = #lines

  local function sign(lnum, text, hl)
    lnum = math.min(math.max(lnum, 1), count)
    vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, { sign_text = text, sign_hl_group = hl, priority = 6 })
  end

  for _, h in ipairs(hunks) do
    local _, count_a, start_b, count_b = unpack(h)
    if count_a == 0 then
      for l = start_b, start_b + count_b - 1 do
        sign(l, "┃", "Added")
      end
    elseif count_b == 0 then
      -- Deleted lines sit between start_b and start_b + 1.
      if start_b == 0 then
        sign(1, "‾", "Removed")
      else
        sign(start_b, "_", "Removed")
      end
    else
      for l = start_b, start_b + count_b - 1 do
        sign(l, "┃", "Changed")
      end
    end
  end
end

local function refresh(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.bo[buf].buftype ~= "" then
    return
  end
  local dir = vim.fs.dirname(path)
  if vim.fn.isdirectory(dir) == 0 then
    return
  end
  vim.system({ "git", "show", ":./" .. vim.fs.basename(path) }, { cwd = dir, text = true }, function(result)
    vim.schedule(function()
      base[buf] = result.code == 0 and result.stdout or false
      render(buf)
    end)
  end)
end

local function debounced_render(buf)
  if base[buf] == nil then
    return
  end
  local timer = timers[buf]
  if not timer then
    timer = assert(vim.uv.new_timer())
    timers[buf] = timer
  end
  timer:stop()
  timer:start(100, 0, vim.schedule_wrap(function() render(buf) end))
end

function M.reset_hunk()
  local buf = vim.api.nvim_get_current_buf()
  if not base[buf] then
    vim.notify("Not a tracked file", vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local hunks = vim.text.diff(base[buf], table.concat(lines, "\n") .. "\n", { result_type = "indices" })
  local lnum = vim.fn.line(".")
  local base_lines = vim.split(base[buf], "\n", { plain = true })
  for _, h in ipairs(hunks) do
    local start_a, count_a, start_b, count_b = unpack(h)
    -- A pure deletion has no lines in the buffer; its sign sits on start_b.
    local first = count_b == 0 and math.max(start_b, 1) or start_b
    local last = count_b == 0 and first or start_b + count_b - 1
    if lnum >= first and lnum <= last then
      local original = count_a > 0 and vim.list_slice(base_lines, start_a, start_a + count_a - 1) or {}
      if count_b == 0 then
        vim.api.nvim_buf_set_lines(buf, start_b, start_b, true, original)
      else
        vim.api.nvim_buf_set_lines(buf, start_b - 1, start_b - 1 + count_b, true, original)
      end
      render(buf)
      return
    end
  end
  vim.notify("No unstaged change under the cursor", vim.log.levels.INFO)
end

function M.setup()
  vim.api.nvim_create_user_command(
    "GitResetHunk",
    M.reset_hunk,
    { desc = "Discard the unstaged hunk under the cursor" }
  )
  local group = vim.api.nvim_create_augroup("mvim_gitsigns", {})
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "FocusGained" }, {
    group = group,
    callback = function(args) refresh(args.buf) end,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args) debounced_render(args.buf) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      base[args.buf] = nil
      if timers[args.buf] then
        timers[args.buf]:close()
        timers[args.buf] = nil
      end
    end,
  })
end

return M
