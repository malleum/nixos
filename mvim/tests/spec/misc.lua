-- Treesitter, comment badges, spell, sessions, :Direnv, help, directory
-- browsing and startup wiring.

local langs = {
  "bash",
  "comment",
  "cpp",
  "css",
  "diff",
  "dockerfile",
  "eex",
  "elixir",
  "gitcommit",
  "git_rebase",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "heex",
  "html",
  "java",
  "javascript",
  "jsdoc",
  "json",
  "make",
  "nix",
  "printf",
  "python",
  "regex",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "typst",
  "yaml",
  "zig",
  "c",
  "lua",
  "markdown",
  "vim",
  "vimdoc",
  "query",
}

test("every grammar's highlight and injection queries compile", function(c)
  local failures = c:lua(
    [[local failures = {}
      for _, lang in ipairs(...) do
        for _, kind in ipairs({ "highlights", "injections" }) do
          local ok, err = pcall(vim.treesitter.query.get, lang, kind)
          if not ok then table.insert(failures, lang .. " " .. kind .. ": " .. tostring(err)) end
        end
      end
      return failures]],
    langs
  )
  eq({}, failures)
end)

test("treesitter starts shortly after a file opens", function(c)
  local path = c:write("a.ts", { "const a: number = 1;" })
  c:edit(path)
  c:wait_for([[vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil]], 2000)
end)

test("TODO badges only inside comments", function(c)
  local files = {
    ["a.lua"] = { "-- TODO: x", "local TODO = 1" },
    ["a.nix"] = { "# FIXME: x", "{ TODO = 1; }" },
    ["a.py"] = { "# HACK: x", "TODO = 1" },
    ["a.c"] = { "// WIP: x", "int TODO = 1;" },
    ["a.vim"] = { '" NOTE: x', "let TODO = 1" },
  }
  local expected = {
    ["a.lua"] = "comment.todo",
    ["a.nix"] = "comment.error",
    ["a.py"] = "comment.warning",
    ["a.c"] = "comment.todo",
    ["a.vim"] = "comment.note",
  }
  for name, lines in pairs(files) do
    c:edit(c:write(name, lines))
    c:wait_for([[vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil]])
    local captures = c:lua([[
      vim.treesitter.get_parser(0):parse(true)
      local function at(row)
        local col = vim.fn.getline(row + 1):find("%u%u%u+") - 1
        return vim.tbl_map(function(c) return c.capture end, vim.treesitter.get_captures_at_pos(0, row, col))
      end
      return { at(0), at(1) }]])
    assert(vim.tbl_contains(captures[1], expected[name]), name .. " comment: " .. vim.inspect(captures[1]))
    assert(
      not vim.iter(captures[2]):any(function(x) return x:find("^comment") end),
      name .. " code: " .. vim.inspect(captures[2])
    )
  end
end)

test("spell checking in markdown and commit messages", function(c)
  for _, file in ipairs({ { "a.md", "This sentance has a typo." }, { "COMMIT_EDITMSG", "fix speling" } }) do
    c:edit(c:write(file[1], { file[2] }))
    local bad = c:lua([[local bad = {}
      for w in vim.api.nvim_get_current_line():gmatch("%a+") do
        if vim.fn.spellbadword(w)[1] ~= "" then table.insert(bad, w) end
      end
      return { vim.wo.spell, bad }]])
    eq(true, bad[1], file[1] .. " spell")
    eq(1, #bad[2], file[1] .. " misspelled words " .. vim.inspect(bad[2]))
  end
end)

test("sessions: save on exit, restore, prune old ones", function(c)
  c:edit(c:write("a.txt", { "hello" }))
  c:cmd("AutoSession save")
  local dir = c.home .. "/state/nvim/sessions"
  local files = vim.fn.glob(dir .. "/*.vim", false, true)
  eq(1, #files, "session files")
  vim.fn.writefile({}, dir .. "/%old.vim")
  vim.uv.fs_utime(dir .. "/%old.vim", os.time() - 40 * 86400, os.time() - 40 * 86400)
  c:cmd("enew")
  c:cmd("AutoSession restore")
  eq("a.txt", c:lua([[return vim.fn.expand("%:t")]]))
  c:lua([[vim.api.nvim_exec_autocmds("VimLeavePre", {})]])
  eq(0, vim.fn.filereadable(dir .. "/%old.vim"), "old session pruned")
  eq(1, vim.fn.filereadable(files[1]), "current session kept")
end)

test(":Direnv loads the environment only when asked", function(c)
  if vim.fn.executable("direnv") == 0 then
    return io.write("  (skipped: no direnv)\n")
  end
  c:write(".envrc", { "export MVIM_TEST=loaded" })
  c:sh("direnv allow .")
  c:cmd("cd " .. c.work)
  c:settle(300)
  eq(vim.NIL, c:lua("return vim.env.MVIM_TEST"), "not loaded automatically")
  c:cmd("Direnv")
  c:wait_for([[vim.env.MVIM_TEST == "loaded"]], 10000)
end)

test(":help mvim opens the help page", function(c)
  c:cmd("help mvim")
  eq("mvim.txt", c:lua([[return vim.fn.expand("%:t")]]))
  c:cmd("help mvim-multicursor")
  assert(c:line():find("mvim%-multicursor"))
end)

test("- browses directories and <C-o> comes back", function(c)
  c:write("sub/one.txt", { "1" })
  c:write("sub/two.txt", { "2" })
  c:edit("sub/two.txt")
  c:keys("-")
  eq({ "one.txt", "two.txt" }, c:lines())
  eq("two.txt", c:line(), "cursor on the file you left")
  c:keys("-")
  eq("sub/", c:line(), "cursor on the directory you left")
  c:keys("<CR>k<CR>")
  eq("1", c:line())
  c:keys("<C-o>")
  eq("mvimdir", c:lua("return vim.bo.filetype"))
end)

test("LSP server configs resolve", function(c)
  local bad = c:lua([[local bad = {}
    for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
      local name = vim.fn.fnamemodify(f, ":t:r")
      local cfg = vim.lsp.config[name]
      if not (cfg and type(cfg.cmd) == "table" and cfg.filetypes and #cfg.filetypes > 0) then table.insert(bad, name) end
    end
    return bad]])
  eq({}, bad)
end)

test("startup defers LSP setup and leaves git and multicursor unloaded", function(c)
  -- vim.lsp loads just after startup, so wait for that first.
  c:wait_for([[package.loaded["vim.lsp"] ~= nil]])
  local loaded = c:lua([[return {
    git = package.loaded["mvim.git"] ~= nil,
    multicursor = package.loaded["mvim.multicursor"] ~= nil,
  }]])
  eq({ git = false, multicursor = false }, loaded)
end)

test("K without a language server opens nothing", function(c)
  c:edit(c:write("a.txt", { "word" }))
  local before = c:lua("return #vim.api.nvim_list_wins()")
  c:keys("K")
  c:settle()
  eq(before, c:lua("return #vim.api.nvim_list_wins()"), "no window opened")
  eq(
    "No language server attached (:Direnv loads a devshell's)",
    c:lua([==[return vim.split(vim.api.nvim_exec2("messages", { output = true }).output, "\n")[1]]==])
  )
end)
