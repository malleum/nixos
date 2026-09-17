-- The <leader>g status page, :GitResetHunk and :GitBlame, against a scratch
-- repository with a bare "remote".

-- Answers yes/no prompts (vim.fn.confirm) in the child: a headless neovim
-- doesn't read the answer from typed keys.
local function answer(c, yes) c:lua("local choice = ...; vim.fn.confirm = function() return choice end", yes and 1 or 2) end

-- A repo with a committed 20-line n.txt and k.txt, then: n.txt changed on
-- lines 2 and 18 (two hunks), k.txt with a line added, untracked u.txt.
local function repo(c)
  c:sh([[
    git init -q -b main .
    seq 1 20 > n.txt
    printf 'k\n' > k.txt
    git add . && git commit -qm init
    sed -i '2s/.*/TWO/; 18s/.*/EIGHTEEN/' n.txt
    printf 'k\nmore\n' > k.txt
    printf 'junk\n' > u.txt
  ]])
end

-- Staged and unstaged diffs as "-old +new" lines, for comparing.
local function diffs(c)
  local function changed(args)
    local out = c:sh("git diff " .. args .. " -U0 | grep '^[-+][^-+]' || true")
    return out == "" and {} or vim.split(out, "\n")
  end
  return { staged = changed("--cached"), unstaged = changed("") }
end

local function open_page(c)
  c:edit("n.txt")
  c:keys(" g")
  c:wait_for([[vim.bo.filetype == "mvimgit"]])
end

-- Puts the cursor on the first page line matching a Lua pattern.
local function goto_line(c, pattern)
  local row = c:lua(
    [[for i, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
        if l:find(...) then vim.api.nvim_win_set_cursor(0, { i, 0 }) return i end
      end]],
    pattern
  )
  assert(row, "no page line matches " .. pattern)
end

test("page shows branch, sections and diff stat", function(c)
  repo(c)
  open_page(c)
  local text = table.concat(c:lines(), "\n")
  for _, expected in ipairs({ "Head: main", "Untracked files %(1%)", "u.txt", "Unstaged changes %(2%)", "n.txt | 4" }) do
    assert(text:find(expected), "page lacks " .. expected .. ":\n" .. text)
  end
end)

test("s / u stage and unstage a file", function(c)
  repo(c)
  open_page(c)
  goto_line(c, "^  M k.txt")
  c:keys("s")
  eq({ "+more" }, diffs(c).staged)
  goto_line(c, "^  M k.txt")
  c:keys("u")
  eq({}, diffs(c).staged)
end)

test("s / u on a hunk stage and unstage just that hunk", function(c)
  repo(c)
  open_page(c)
  goto_line(c, "^  M n.txt")
  c:keys("<Tab>")
  goto_line(c, "%+EIGHTEEN")
  c:keys("s")
  eq({ "-18", "+EIGHTEEN" }, diffs(c).staged)
  eq({ "+more", "-2", "+TWO" }, diffs(c).unstaged)
  goto_line(c, "^Staged changes")
  c:keys("j<Tab>")
  goto_line(c, "%+EIGHTEEN")
  c:keys("u")
  eq({}, diffs(c).staged)
end)

test("x on a hunk discards it after yes, keeps it after no", function(c)
  repo(c)
  open_page(c)
  goto_line(c, "^  M n.txt")
  c:keys("<Tab>")
  goto_line(c, "%+EIGHTEEN")
  answer(c, false)
  c:keys("x")
  eq("EIGHTEEN", c:sh("sed -n 18p n.txt"))
  goto_line(c, "%+TWO")
  answer(c, true)
  c:keys("x")
  eq("2", c:sh("sed -n 2p n.txt"))
end)

test("x on a file discards all its changes; on untracked deletes it", function(c)
  repo(c)
  open_page(c)
  goto_line(c, "^  M k.txt")
  answer(c, true)
  c:keys("x")
  eq("k", c:sh("cat k.txt"))
  goto_line(c, "^  %? u.txt")
  answer(c, true)
  c:keys("x")
  eq("no", c:sh("test -e u.txt && echo yes || echo no"))
end)

test("x on the file line of an open diff does nothing", function(c)
  repo(c)
  open_page(c)
  goto_line(c, "^  M n.txt")
  c:keys("<Tab>")
  goto_line(c, "^  M n.txt")
  c:keys("x")
  eq("TWO", c:sh("sed -n 2p n.txt"))
end)

test("S stages everything, U unstages everything", function(c)
  repo(c)
  open_page(c)
  c:keys("S")
  eq("", c:sh("git status --porcelain | grep -v '^[AM] ' || true"))
  c:keys("U")
  eq("", c:sh("git diff --cached --name-only"))
end)

test("c commits with the written message; P pushes and sets upstream", function(c)
  repo(c)
  c:sh("git init -q --bare ../remote.git && git remote add origin ../remote.git")
  open_page(c)
  c:keys("S")
  c:keys("c")
  c:wait_for([[vim.bo.filetype == "gitcommit"]])
  c:keys("ggitest message<Esc>:wq<CR>")
  c:wait_for([[vim.bo.filetype == "mvimgit"]])
  c:settle(200)
  eq("test message", c:sh("git log -1 --format=%s"))
  c:keys("P")
  c:wait_for(
    [[vim.fn.system("git -C ]]
      .. c.work
      .. [[ rev-parse --abbrev-ref @{upstream} 2>/dev/null"):find("origin/main") ~= nil]],
    10000
  )
  eq(c:sh("git rev-parse HEAD"), c:sh("git --git-dir=../remote.git rev-parse main"))
end)

test(":GitResetHunk restores a changed line and removes an added one", function(c)
  c:sh([[git init -q -b main . && seq 1 20 > n.txt && git add . && git commit -qm init]])
  c:edit("n.txt")
  c:wait_for([[#vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, {}) == 0]])
  c:lua([[vim.fn.setline(10, "TEN"); vim.fn.append(14, "inserted")]])
  c:settle(200)
  c:cmd("10")
  c:cmd("GitResetHunk")
  c:cmd("15")
  c:cmd("GitResetHunk")
  eq(vim.split(c:sh("seq 1 20"), "\n"), c:lines())
end)

test(":GitBlame shows commit info for a line and a range", function(c)
  c:sh([[git init -q -b main . && seq 1 5 > n.txt && git add . && git commit -qm "first commit"]])
  c:edit("n.txt")
  c:lua([[vim.fn.setline(2, "unsaved")]])
  local function float_text()
    return c:lua([[for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(w).relative ~= "" then
          local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false), "\n")
          vim.api.nvim_win_close(w, true)
          return text
        end
      end]])
  end
  c:cmd("3GitBlame")
  local one = float_text()
  assert(one:find("first commit") and one:find("Test"), one)
  c:cmd("1,3GitBlame")
  local range = float_text()
  assert(range:find("2  Not committed yet") and range:find("3  %x+"), range)
end)

test("git page loads on first use", function(c) eq(false, c:lua([[return package.loaded["mvim.git"] ~= nil]])) end)
