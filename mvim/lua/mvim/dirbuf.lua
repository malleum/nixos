-- Oil-style directory browsing, read-only. A directory is a buffer named by
-- its path, listing one entry per line (directories end in "/").
--   -      open the parent directory, cursor on the file or directory you left
--   <CR>   open the entry under the cursor
--   g.     toggle dotfiles
--   <C-o>  back (entries open with :edit, so the jumplist records them)
-- `nvim some/dir` and `:edit some/dir` open the same view.
local M = {}

local show_hidden = false
local focus = {} -- directory path -> entry name to put the cursor on

local function is_dir(path) return vim.fn.isdirectory(path) == 1 end

-- Absolute path with a trailing slash, the form every directory buffer uses.
local function dir_path(path) return vim.fn.fnamemodify(path, ":p") end

local function open(path, focus_name)
  path = dir_path(path)
  if is_dir(path) then
    focus[path] = focus_name
  end
  -- Relative to the working directory, which is "" for the directory itself.
  local display = vim.fn.fnamemodify(path, ":~:.")
  vim.cmd.edit(vim.fn.fnameescape(display == "" and "." or display))
end

local function parent(dir)
  local trimmed = dir:gsub("/$", "")
  if trimmed == "" then
    return nil
  end
  return vim.fn.fnamemodify(trimmed, ":h"), vim.fn.fnamemodify(trimmed, ":t") .. "/"
end

local function list(dir)
  local entries = {}
  for name, type in vim.fs.dir(dir) do
    if show_hidden or name:sub(1, 1) ~= "." then
      local directory = type == "directory" or (type == "link" and is_dir(dir .. name))
      table.insert(entries, { name = name, directory = directory })
    end
  end
  table.sort(entries, function(a, b)
    if a.directory ~= b.directory then
      return a.directory
    end
    return a.name:lower() < b.name:lower()
  end)
  return vim.tbl_map(function(e) return e.name .. (e.directory and "/" or "") end, entries)
end

local function set_maps(buf)
  local function map(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true }) end
  map("<CR>", function()
    local entry = vim.api.nvim_get_current_line()
    if entry ~= "" then
      open(dir_path(vim.api.nvim_buf_get_name(buf)) .. entry)
    end
  end)
  map("-", function()
    local up, child = parent(dir_path(vim.api.nvim_buf_get_name(buf)))
    if up then
      open(up, child)
    end
  end)
  map("g.", function()
    show_hidden = not show_hidden
    M.render(buf)
  end)
end

function M.render(buf)
  local dir = dir_path(vim.api.nvim_buf_get_name(buf))
  local lines = list(dir)
  local bo = vim.bo[buf]
  bo.buftype = "nofile"
  bo.bufhidden = "hide"
  bo.swapfile = false
  bo.modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  bo.modifiable = false
  bo.modified = false
  if bo.filetype ~= "mvimdir" then
    bo.filetype = "mvimdir"
    set_maps(buf)
  end

  local target = focus[dir]
  focus[dir] = nil
  if target and vim.api.nvim_get_current_buf() == buf then
    for i, line in ipairs(lines) do
      if line == target then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        break
      end
    end
  end
end

function M.setup()
  vim.api.nvim_set_hl(0, "MvimDirDirectory", { link = "Directory", default = true })
  local group = vim.api.nvim_create_augroup("mvim_dirbuf", {})

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      if is_dir(vim.api.nvim_buf_get_name(args.buf)) then
        M.render(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "mvimdir",
    callback = function() vim.cmd([[syntax match MvimDirDirectory /^.*\/$/]]) end,
  })

  vim.keymap.set("n", "-", function()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" or vim.bo.buftype ~= "" then
      open(vim.fn.getcwd())
    else
      open(vim.fn.fnamemodify(name, ":p:h"), vim.fn.fnamemodify(name, ":t"))
    end
  end, { desc = "Open parent directory" })
end

return M
