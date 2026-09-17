-- A small neogit stand-in. <leader>g opens a status buffer for the repo of the
-- current file (or working directory):
--
--   s / u      stage / unstage the file under the cursor; on a hunk of a shown
--              diff, just that hunk; on a section heading, every file in it;
--              in visual mode, every selected file
--   x          discard (asks first): the unstaged hunk under the cursor, or on
--              a file whose diff isn't shown, all its unstaged changes (an
--              untracked file is deleted)
--   S / U      stage everything / unstage everything
--   <Tab>      show or hide the file's diff inline
--   <CR>       open the file
--   c          commit: write the message, then :wq (:q! aborts)
--   p          pull            P  push (sets the upstream on a first push)
--   !          force push (--force-with-lease, asks first)
--   r          refresh         q  close
--
-- In any buffer:
--   :GitBlame  who last changed the current line (or a visual range), in a
--              float that closes when the cursor moves
local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("mvim_git")
local pages = {} -- status buffer -> { root, expanded, items }

local help =
  "s stage  u unstage  x discard  S/U all  <Tab> diff  <CR> open  c commit  p pull  P push  ! force push  r refresh  q close"

-- Runs git synchronously in `root`. Returns ok, stdout, stderr.
local function git(root, args)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = root, text = true }):wait()
  return result.code == 0, result.stdout or "", result.stderr or ""
end

-- Runs a slow git command (pull/push) without blocking, then calls `done`.
local function git_async(root, args, done)
  local env = { GIT_TERMINAL_PROMPT = "0" } -- fail instead of waiting for a password prompt
  vim.system(vim.list_extend({ "git" }, args), { cwd = root, text = true, env = env }, function(result)
    vim.schedule(function() done(result.code == 0, result.stdout or "", result.stderr or "") end)
  end)
end

local function notify_output(title, ok, out, err)
  local text = vim.trim((out or "") .. "\n" .. (err or ""))
  vim.notify(title .. (text ~= "" and (":\n" .. text) or ""), ok and vim.log.levels.INFO or vim.log.levels.ERROR)
end

local function repo_root()
  local name = api.nvim_buf_get_name(0)
  local dir = (name ~= "" and vim.bo.buftype == "") and vim.fs.dirname(name) or vim.fn.getcwd()
  if vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  local ok, out = git(dir, { "rev-parse", "--show-toplevel" })
  return ok and vim.trim(out) or nil
end

-- Parses `git status --porcelain=v1 -b -z`.
local function status(root)
  local _, out = git(root, { "status", "--porcelain=v1", "-b", "-z", "--untracked-files=all" })
  local entries = vim.split(out, "\0", { trimempty = true })
  local result = { branch = "", untracked = {}, unstaged = {}, staged = {} }
  local i = 1
  while i <= #entries do
    local entry = entries[i]
    if vim.startswith(entry, "## ") then
      result.branch = entry:sub(4)
    else
      local x, y, path = entry:sub(1, 1), entry:sub(2, 2), entry:sub(4)
      if x == "?" then
        table.insert(result.untracked, { path = path, code = "?" })
      else
        if x ~= " " then
          table.insert(result.staged, { path = path, code = x })
        end
        if y ~= " " then
          table.insert(result.unstaged, { path = path, code = y })
        end
        if x == "R" or x == "C" then
          i = i + 1 -- renames and copies are followed by the original path
        end
      end
    end
    i = i + 1
  end
  return result
end

local sections = {
  { key = "untracked", title = "Untracked files" },
  { key = "unstaged", title = "Unstaged changes" },
  { key = "staged", title = "Staged changes" },
}

-- A file's diff split into its header and hunks (each a list of lines).
local function file_diff(root, section, path)
  local _, out
  if section == "untracked" then
    _, out = git(root, { "diff", "--no-color", "--no-index", "--", "/dev/null", path })
  elseif section == "staged" then
    _, out = git(root, { "diff", "--no-color", "--cached", "--", path })
  else
    _, out = git(root, { "diff", "--no-color", "--", path })
  end
  local diff = { header = {}, hunks = {} }
  for _, line in ipairs(vim.split(out, "\n", { trimempty = true })) do
    if vim.startswith(line, "@@") then
      table.insert(diff.hunks, { line })
    elseif #diff.hunks > 0 then
      table.insert(diff.hunks[#diff.hunks], line)
    else
      table.insert(diff.header, line)
    end
  end
  return diff
end

local function render(buf)
  local s = pages[buf]
  local root = s.root
  local st = status(root)
  local lines, items, marks = {}, {}, {}
  local function add(line, item, hl)
    table.insert(lines, line)
    items[#lines] = item
    if hl then
      table.insert(marks, { #lines - 1, hl })
    end
  end

  add("Head: " .. st.branch, nil, "Title")
  add(help, nil, "Comment")
  for _, section in ipairs(sections) do
    local files = st[section.key]
    if #files > 0 then
      add("", nil)
      add(("%s (%d)"):format(section.title, #files), { section = section.key }, "Label")
      for _, file in ipairs(files) do
        local expanded = s.expanded[section.key .. "\0" .. file.path]
        add(("  %s %s"):format(file.code, file.path), { section = section.key, path = file.path }, "Directory")
        if expanded then
          local diff = file_diff(root, section.key, file.path)
          for index, hunk in ipairs(diff.hunks) do
            local hunk_item = { section = section.key, path = file.path, diff = diff, hunk = index }
            for _, line in ipairs(hunk) do
              local first = line:sub(1, 1)
              local hl = vim.startswith(line, "@@") and "Function"
                or first == "+" and "Added"
                or first == "-" and "Removed"
                or nil
              add("    " .. line, hunk_item, hl)
            end
          end
        end
      end
    end
  end
  if #st.untracked + #st.unstaged + #st.staged == 0 then
    add("", nil)
    add("Nothing to commit, working tree clean", nil, "Comment")
  end

  for _, cached in ipairs({ false, true }) do
    local args = { "diff", "--no-color", "--stat" }
    if cached then
      table.insert(args, "--cached")
    end
    local _, out = git(root, args)
    if vim.trim(out) ~= "" then
      add("", nil)
      add(cached and "Staged diff --stat" or "Unstaged diff --stat", nil, "Label")
      for _, line in ipairs(vim.split(out, "\n", { trimempty = true })) do
        add(line, nil)
      end
    end
  end

  local view = vim.fn.winsaveview()
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(buf, ns, m[1], 0, { end_row = m[1] + 1, hl_group = m[2], hl_eol = false })
  end
  s.items = items
  vim.fn.winrestview(view)
end

-- Files the cursor (or visual selection) refers to, grouped as
-- { section = ..., paths = { ... } }.
local function targets(buf, first, last)
  local s = pages[buf]
  local by_section, order = {}, {}
  local function add(section, path)
    if not by_section[section] then
      by_section[section] = {}
      table.insert(order, section)
    end
    if not vim.tbl_contains(by_section[section], path) then
      table.insert(by_section[section], path)
    end
  end
  local st
  for lnum = first, last do
    local item = s.items[lnum]
    if item and item.path then
      add(item.section, item.path)
    elseif item then
      st = st or status(s.root)
      for _, file in ipairs(st[item.section]) do
        add(item.section, file.path)
      end
    end
  end
  return vim.tbl_map(function(section) return { section = section, paths = by_section[section] } end, order)
end

-- Applies one hunk of a shown diff with `git apply <flags>`.
local function apply_hunk(root, item, flags)
  local patch = table.concat(item.diff.header, "\n") .. "\n" .. table.concat(item.diff.hunks[item.hunk], "\n") .. "\n"
  local result =
    vim.system(vim.list_extend({ "git", "apply" }, flags), { cwd = root, stdin = patch, text = true }):wait()
  if result.code ~= 0 then
    notify_output("git apply", false, result.stdout, result.stderr)
  end
  return result.code == 0
end

local function stage(buf, first, last)
  local item = pages[buf].items[first]
  if first == last and item and item.hunk and item.section == "unstaged" then
    apply_hunk(pages[buf].root, item, { "--cached" })
    return render(buf)
  end
  local root = pages[buf].root
  for _, group in ipairs(targets(buf, first, last)) do
    if group.section ~= "staged" then
      local ok, out, err = git(root, vim.list_extend({ "add", "--" }, group.paths))
      if not ok then
        notify_output("git add", ok, out, err)
      end
    end
  end
  render(buf)
end

local function unstage(buf, first, last)
  local item = pages[buf].items[first]
  if first == last and item and item.hunk and item.section == "staged" then
    apply_hunk(pages[buf].root, item, { "--cached", "--reverse" })
    return render(buf)
  end
  local root = pages[buf].root
  for _, group in ipairs(targets(buf, first, last)) do
    if group.section == "staged" then
      local ok, out, err = git(root, vim.list_extend({ "restore", "--staged", "--" }, group.paths))
      if not ok then
        -- No commits yet: there is no HEAD to restore from.
        ok, out, err = git(root, vim.list_extend({ "rm", "--cached", "-r", "-q", "--" }, group.paths))
      end
      if not ok then
        notify_output("git unstage", ok, out, err)
      end
    end
  end
  render(buf)
end

-- x: on a hunk of a shown unstaged diff, discard that hunk. On a file line whose
-- diff isn't shown, discard the whole file: unstaged changes go back to the
-- staged version (git restore), an untracked file is deleted (git clean).
local function discard(buf)
  local s = pages[buf]
  local item = s.items[vim.fn.line(".")]
  local function done()
    vim.cmd("silent! checktime") -- reload the file if it's open
    render(buf)
  end

  if item and item.hunk and item.section == "unstaged" then
    if vim.fn.confirm("Discard this hunk from " .. item.path .. "?", "&Yes\n&No", 2) == 1 then
      apply_hunk(s.root, item, { "--reverse" })
      done()
    end
    return
  end

  local expanded = item and item.path and s.expanded[item.section .. "\0" .. item.path]
  if item and item.path and not item.hunk and not expanded then
    local prompt, args
    if item.section == "unstaged" then
      prompt, args = "Discard all unstaged changes to " .. item.path .. "?", { "restore", "--", item.path }
    elseif item.section == "untracked" then
      prompt, args = "Delete untracked file " .. item.path .. "?", { "clean", "-f", "--", item.path }
    end
    if prompt then
      if vim.fn.confirm(prompt, "&Yes\n&No", 2) == 1 then
        local ok, out, err = git(s.root, args)
        if not ok then
          notify_output("git " .. args[1], ok, out, err)
        end
        done()
      end
      return
    end
  end

  vim.notify(
    "x discards an unstaged hunk, or an unstaged or untracked file whose diff isn't shown",
    vim.log.levels.INFO
  )
end

local function commit(buf)
  local root = pages[buf].root
  local _, staged = git(root, { "diff", "--cached", "--stat" })
  if vim.trim(staged) == "" then
    vim.notify("Nothing staged to commit", vim.log.levels.WARN)
    return
  end
  local file = vim.fn.tempname() .. "_COMMIT_EDITMSG"
  local template =
    { "", "# Write the message, then :wq to commit (:q! to abort). Lines starting with # are ignored.", "#" }
  for _, line in ipairs(vim.split(staged, "\n", { trimempty = true })) do
    table.insert(template, "# " .. line)
  end
  vim.fn.writefile(template, file)
  vim.cmd("botright split " .. vim.fn.fnameescape(file))
  local msg_buf = api.nvim_get_current_buf()
  vim.bo[msg_buf].filetype = "gitcommit"
  vim.bo[msg_buf].bufhidden = "wipe"
  local saved = false
  api.nvim_create_autocmd("BufWritePost", { buffer = msg_buf, callback = function() saved = true end })
  api.nvim_create_autocmd("BufWipeout", {
    buffer = msg_buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if saved then
          local ok, out, err = git(root, { "commit", "--cleanup=strip", "-F", file })
          notify_output(ok and "Committed" or "git commit failed", ok, out, err)
        else
          vim.notify("Commit aborted", vim.log.levels.INFO)
        end
        os.remove(file)
        if api.nvim_buf_is_valid(buf) then
          render(buf)
        end
      end)
    end,
  })
end

local function remote_op(buf, title, args, retry_upstream)
  local root = pages[buf].root
  vim.notify(title .. "...", vim.log.levels.INFO)
  git_async(root, args, function(ok, out, err)
    if not ok and retry_upstream and err:find("has no upstream branch", 1, true) then
      local _, branch = git(root, { "branch", "--show-current" })
      return remote_op(buf, title .. " (setting upstream)", { "push", "-u", "origin", vim.trim(branch) }, false)
    end
    notify_output(ok and (title .. " done") or (title .. " failed"), ok, out, err)
    if api.nvim_buf_is_valid(buf) then
      render(buf)
    end
  end)
end

local function line_range()
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  return math.min(a, b), math.max(a, b)
end

local function set_maps(buf)
  local function map(mode, lhs, fn) vim.keymap.set(mode, lhs, fn, { buffer = buf, nowait = true }) end
  local function lnum() return vim.fn.line(".") end
  local function item() return pages[buf].items[lnum()] end

  map("n", "s", function() stage(buf, lnum(), lnum()) end)
  map("n", "u", function() unstage(buf, lnum(), lnum()) end)
  map("x", "s", function() stage(buf, line_range()) end)
  map("x", "u", function() unstage(buf, line_range()) end)
  map("n", "S", function()
    git(pages[buf].root, { "add", "-A" })
    render(buf)
  end)
  map("n", "U", function()
    local root = pages[buf].root
    if not git(root, { "reset", "-q" }) then
      git(root, { "rm", "--cached", "-r", "-q", "." })
    end
    render(buf)
  end)
  map("n", "<Tab>", function()
    local it = item()
    if not (it and it.path) then
      return
    end
    local s = pages[buf]
    local key = it.section .. "\0" .. it.path
    s.expanded[key] = not s.expanded[key] or nil
    render(buf)
  end)
  map("n", "<CR>", function()
    local it = item()
    if it and it.path then
      vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(pages[buf].root, it.path)))
    end
  end)
  map("n", "x", function() discard(buf) end)
  map("n", "c", function() commit(buf) end)
  map("n", "p", function() remote_op(buf, "Pull", { "pull" }) end)
  map("n", "P", function() remote_op(buf, "Push", { "push" }, true) end)
  map("n", "!", function()
    if vim.fn.confirm("Force push (--force-with-lease)?", "&Yes\n&No", 2) == 1 then
      remote_op(buf, "Force push", { "push", "--force-with-lease" }, true)
    end
  end)
  map("n", "r", function() render(buf) end)
  map("n", "q", function()
    if vim.fn.bufnr("#") > 0 and vim.fn.buflisted(vim.fn.bufnr("#")) == 1 then
      vim.cmd("buffer #")
    else
      vim.cmd("enew")
    end
  end)
end

function M.open()
  local root = repo_root()
  if not root then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  local name = "mvimgit://" .. root
  local buf = vim.fn.bufnr(name)
  if buf == -1 then
    buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(buf, name)
    vim.bo[buf].filetype = "mvimgit"
    vim.bo[buf].bufhidden = "hide"
    pages[buf] = { root = root, expanded = {}, items = {} }
    api.nvim_create_autocmd("BufWipeout", { buffer = buf, callback = function() pages[buf] = nil end })
    set_maps(buf)
  end
  api.nvim_set_current_buf(buf)
  render(buf)
end

-- :GitBlame for lines first..last of the current buffer, including unsaved
-- edits (those show as not committed yet).
function M.blame(first, last)
  local path = api.nvim_buf_get_name(0)
  if path == "" or vim.bo.buftype ~= "" then
    return vim.notify("Not a file", vim.log.levels.WARN)
  end
  local text = table.concat(api.nvim_buf_get_lines(0, 0, -1, true), "\n") .. "\n"
  local args =
    { "git", "blame", "--porcelain", "-L", first .. "," .. last, "--contents", "-", "--", vim.fs.basename(path) }
  local result = vim.system(args, { cwd = vim.fs.dirname(path), stdin = text, text = true }):wait()
  if result.code ~= 0 then
    return notify_output("git blame", false, "", result.stderr)
  end

  local commits, rows, sha = {}, {}, nil
  for _, line in ipairs(vim.split(result.stdout, "\n", { trimempty = true })) do
    local hash = line:match("^(%x+) %d+ %d+")
    if hash and #hash == 40 then
      sha = hash
      commits[sha] = commits[sha] or {}
    elseif vim.startswith(line, "\t") then
      table.insert(rows, sha)
    else
      local key, value = line:match("^(%S+) (.*)$")
      if key == "author" or key == "author-time" or key == "summary" then
        commits[sha][key] = value
      end
    end
  end

  local function describe(hash)
    local c = commits[hash]
    if hash:match("^0+$") then
      return "Not committed yet"
    end
    local date = os.date("%Y-%m-%d", tonumber(c["author-time"]))
    return ("%s  %s  %s  %s"):format(hash:sub(1, 8), date, c.author or "?", c.summary or "")
  end

  local lines = {}
  if #rows == 1 then
    lines = { describe(rows[1]) }
  else
    for i, hash in ipairs(rows) do
      table.insert(lines, ("%d  %s"):format(first + i - 1, describe(hash)))
    end
  end
  vim.lsp.util.open_floating_preview(lines, "", { focus_id = "mvim_git_blame" })
end

function M.setup()
  vim.api.nvim_create_user_command(
    "GitBlame",
    function(opts) M.blame(opts.line1, opts.line2) end,
    { range = true, desc = "Who last changed these lines" }
  )
  vim.keymap.set("n", "<leader>g", M.open, { desc = "Git status" })
  -- Keep the page current when coming back to it (after editing a file, say).
  api.nvim_create_autocmd("BufEnter", {
    pattern = "mvimgit://*",
    callback = function(args)
      if pages[args.buf] then
        render(args.buf)
      end
    end,
  })
end

return M
