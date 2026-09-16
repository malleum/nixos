-- fzf in a floating terminal, standing in for telescope. fzf writes its
-- selection to a temp file; on exit the float closes and the result is opened.
local M = {}

local function strip_ansi(s) return (s:gsub("\27%[[%d;]*m", "")) end

-- Size of the floating window fzf runs in.
local function float_size() return math.floor(vim.o.columns * 0.95), math.floor(vim.o.lines * 0.8) end

-- Runs `source | fzf <args>` in `cwd` and passes the selected lines to `on_select`.
local function fzf(source, args, cwd, on_select)
  local width, height = float_size()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
  })

  local out = vim.fn.tempname()
  -- <C-d>/<C-u> scroll the preview by half a page, as in a buffer. They
  -- replace fzf's delete-char and clear-query; <C-w> still deletes a word.
  local keys = "--bind ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up"
  local cmd = ("%s | fzf --layout=reverse %s %s > %s"):format(source, keys, args, vim.fn.shellescape(out))
  vim.fn.jobstart(cmd, {
    term = true,
    cwd = cwd,
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        local lines = code == 0 and vim.fn.readfile(out) or {}
        os.remove(out)
        if #lines > 0 then
          on_select(vim.tbl_map(strip_ansi, lines))
        end
      end)
    end,
  })
  vim.cmd.startinsert()
end

local function open(cwd, path, line, col)
  if cwd and not vim.startswith(path, "/") then
    path = vim.fs.joinpath(cwd, path)
  end
  vim.cmd.edit(vim.fn.fnameescape(vim.fn.fnamemodify(path, ":.")))
  if line then
    pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), math.max(tonumber(col or 1) - 1, 0) })
    vim.cmd("normal! zz")
  end
end

local function open_files(cwd)
  return function(lines)
    for _, path in ipairs(lines) do
      open(cwd, path)
    end
  end
end

-- Parses `path:line:col:text` lines as printed by rg --vimgrep style output.
local function open_matches(lines)
  for _, l in ipairs(lines) do
    local path, line, col = l:match("^(.-):(%d+):(%d+):")
    if path then
      open(nil, path, line, col)
    end
  end
end

-- Shell command previewing `file` with bat (theme from its config: tokyonight,
-- modules/programs/cli.nix). bat always pads line numbers to 4 columns; the
-- sed drops the padding the file's line count doesn't need, keeping numbers
-- right-aligned without a gap before them.
local function bat(file, extra)
  return table.concat({
    ("n=$(grep -c '' %s)"):format(file),
    "k=$((4 - ${#n}))",
    "[ $k -lt 0 ] && k=0",
    ('bat --color=always --style=numbers %s %s | sed -E "s/^(\\x1b\\[[0-9;]*m) {$k}/\\1/"'):format(extra or "", file),
  }, "; ")
end

-- Terminal cells are about twice as tall as wide, so the terminal is portrait
-- when it has fewer columns than twice its rows.
local function portrait() return vim.o.columns < vim.o.lines * 2 end

-- Where the preview goes. Portrait: below the list, 60% of the height.
-- Landscape: to the right, two thirds of the width unless a path wouldn't fit
-- in the remaining third, then an even split. Without `paths` (grep results,
-- which include the matched text) it's always an even split.
local function preview_window(paths)
  if portrait() then
    return "down:60%"
  end
  if not paths then
    return "right:50%"
  end
  local inner = float_size() - 2
  local list = inner - math.floor(inner * 0.66)
  local longest = 0
  for _, path in ipairs(paths) do
    longest = math.max(longest, vim.fn.strdisplaywidth(path))
  end
  -- fzf's pointer column, scrollbar and gap take about four columns.
  return longest + 4 <= list and "right:66%" or "right:50%"
end

-- Lists files with `cmd` up front so the split can fit the longest path, then
-- feeds that list to fzf.
local function file_picker(cmd, cwd)
  local result = vim.system({ "sh", "-c", cmd }, { cwd = cwd, text = true }):wait()
  local paths = vim.split(result.stdout or "", "\n", { trimempty = true })
  local list = vim.fn.tempname()
  vim.fn.writefile(paths, list)
  local args = ("--multi --preview %s --preview-window %s"):format(vim.fn.shellescape(bat("{}")), preview_window(paths))
  fzf("cat " .. vim.fn.shellescape(list), args, cwd, function(lines)
    os.remove(list)
    open_files(cwd)(lines)
  end)
end

function M.files(cwd) file_picker("fd --type f --hidden --exclude .git", cwd) end

function M.git_files()
  local root = vim.fs.root(0, ".git") or vim.uv.cwd()
  file_picker("git ls-files --cached --others --exclude-standard", root)
end

local rg = "rg --column --line-number --no-heading --color=always --smart-case"
local function match_args()
  return table.concat({
    "--ansi --multi --delimiter :",
    "--preview " .. vim.fn.shellescape(bat("{1}", "--highlight-line {2}")),
    ("--preview-window '%s,+{2}-/2'"):format(preview_window()),
  }, " ")
end

function M.live_grep()
  local reload = vim.fn.shellescape(rg .. " -- {q} || true")
  fzf(
    "true",
    match_args() .. " --disabled --bind start:reload:" .. reload .. " --bind change:reload:" .. reload,
    nil,
    open_matches
  )
end

function M.grep(text, regex)
  if not text or text == "" then
    return
  end
  local flags = regex and "" or " --fixed-strings"
  fzf(rg .. flags .. " -- " .. vim.fn.shellescape(text), match_args(), nil, open_matches)
end

function M.setup()
  local map = vim.keymap.set
  map("n", "<leader>h", function() M.files() end)
  map("n", "<leader>t", function() M.files(vim.fn.expand("%:p:h")) end)
  map("n", "<leader>pg", M.git_files)
  map("n", "<leader>ps", M.live_grep)
  map("n", "<leader>pw", function() M.grep(vim.fn.expand("<cword>")) end)
  map("n", "<leader>pW", function() M.grep(vim.fn.expand("<cWORD>")) end)
  map("n", "<leader>pS", function() M.grep(vim.fn.input({ prompt = " > " })) end)
  map("n", "<leader>pt", function() M.grep(require("mvim.todo").rg_pattern(), true) end)
  -- Search for the selected text (its first line; grep matches line by line).
  map("x", "<leader>h", function()
    local text = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })[1]
    vim.cmd("normal! \27")
    M.grep(text)
  end)
end

return M
