-- fzf in a floating terminal, standing in for telescope. fzf writes its
-- selection to a temp file; on exit the float closes and the result is opened.
local M = {}

local function strip_ansi(s) return (s:gsub("\27%[[%d;]*m", "")) end

-- Runs `source | fzf <args>` in `cwd` and passes the selected lines to `on_select`.
local function fzf(source, args, cwd, on_select)
  local width = math.floor(vim.o.columns * 0.95)
  local height = math.floor(vim.o.lines * 0.8)
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

-- bat's theme comes from its config (tokyonight, modules/programs/cli.nix).
local bat = "bat --color=always --style=numbers"

local function file_preview() return ("--preview %s"):format(vim.fn.shellescape(bat .. " {}")) end

function M.files(cwd) fzf("fd --type f --hidden --exclude .git", "--multi " .. file_preview(), cwd, open_files(cwd)) end

function M.git_files()
  local root = vim.fs.root(0, ".git") or vim.uv.cwd()
  fzf("git ls-files --cached --others --exclude-standard", "--multi " .. file_preview(), root, open_files(root))
end

local rg = "rg --column --line-number --no-heading --color=always --smart-case"
local function match_args()
  return table.concat({
    "--ansi --multi --delimiter :",
    "--preview " .. vim.fn.shellescape(bat .. " --highlight-line {2} {1}"),
    "--preview-window '+{2}-/2'",
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
