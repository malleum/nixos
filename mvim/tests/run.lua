-- Test runner for mvim. Each test starts a fresh mvim as an embedded child
-- process and drives it with real keystrokes over RPC, the way neovim's own
-- functional tests do, so mappings, autocommands and insert mode behave as
-- they do when typing. Spec files (spec/*.lua) run in parallel, one process
-- each.
--
--   MVIM=/path/to/mvim/bin/nvim nvim --clean -l mvim/tests/run.lua [filter]
--
-- Run by `nix flake check` (checks.<system>.mvim, modules/meta/nvim.nix), or
-- `nix run .#mvim-test -- [filter]`. [filter] is a Lua pattern matched
-- against "file: test name".

local mvim = assert(os.getenv("MVIM"), "set MVIM to the mvim nvim binary")
local script = debug.getinfo(1, "S").source:sub(2)
local dir = vim.fs.dirname(script)
local args = _G.arg
local worker_file = args[1] == "--worker" and args[2] or nil
local filter
if worker_file then
  filter = args[3]
else
  filter = args[1]
end

-- Coordinator: one worker process per spec file, results added up.
if not worker_file then
  local files = vim.fn.glob(dir .. "/spec/*.lua", false, true)
  table.sort(files)
  local start = vim.uv.hrtime()
  local jobs = {}
  for _, file in ipairs(files) do
    local cmd = { vim.v.progpath, "--clean", "-l", script, "--worker", file, filter }
    table.insert(jobs, vim.system(cmd, { text = true }))
  end
  local passed, failed, skipped = 0, 0, 0
  for _, job in ipairs(jobs) do
    local result = job:wait()
    local out = result.stdout or ""
    local p, f, s = out:match("RESULT (%d+) (%d+) (%d+)")
    if p then
      passed, failed, skipped = passed + tonumber(p), failed + tonumber(f), skipped + tonumber(s)
      io.write((out:gsub("RESULT %d+ %d+ %d+\n?", "")))
    else
      failed = failed + 1
      io.write("worker crashed:\n", out, result.stderr or "", "\n")
    end
  end
  local filtered = skipped > 0 and (", " .. skipped .. " filtered out") or ""
  io.write(("%d passed, %d failed%s in %.1fs\n"):format(passed, failed, filtered, (vim.uv.hrtime() - start) / 1e9))
  os.exit(failed == 0 and 0 or 1)
end

-- Worker ---------------------------------------------------------------------

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")

-- What a test's processes see: an isolated home and a git identity.
local function test_env(home)
  return {
    HOME = home,
    XDG_CONFIG_HOME = home .. "/config",
    XDG_DATA_HOME = home .. "/data",
    XDG_STATE_HOME = home .. "/state",
    XDG_CACHE_HOME = home .. "/cache",
    GIT_AUTHOR_NAME = "Test",
    GIT_AUTHOR_EMAIL = "test@example.com",
    GIT_COMMITTER_NAME = "Test",
    GIT_COMMITTER_EMAIL = "test@example.com",
    GIT_CONFIG_GLOBAL = "/dev/null",
  }
end

local Child = {}
Child.__index = Child

local counter = 0

function Child.new()
  counter = counter + 1
  local home = root .. "/" .. counter
  vim.fn.mkdir(home .. "/work", "p")
  local self = setmetatable({ home = home, work = home .. "/work", stderr = {} }, Child)
  self.chan = vim.fn.jobstart({ mvim, "--embed", "--headless", "-n", "-i", "NONE" }, {
    rpc = true,
    cwd = self.work,
    env = test_env(home),
    on_stderr = function(_, data) vim.list_extend(self.stderr, data) end,
  })
  return self
end

function Child:request(method, ...)
  local ok, result = pcall(vim.rpcrequest, self.chan, method, ...)
  if not ok then
    error(("rpc %s failed: %s %s"):format(method, tostring(result), table.concat(self.stderr, "\n")), 2)
  end
  return result
end

-- Runs Lua in the child and returns its result.
function Child:lua(code, ...) return self:request("nvim_exec_lua", code, { ... }) end

function Child:cmd(ex) return self:request("nvim_command", ex) end

-- Sends keys (<> notation) at once, then gives callbacks mvim schedules for
-- "right after this" a moment to run, as the gap between keystrokes would.
function Child:keys(keys)
  self:request("nvim_input", keys)
  self:lua("vim.wait(2)")
end

-- Types text one character at a time, as a keyboard does (insert-mode
-- mappings look at the line between keys).
function Child:type(text)
  for _, char in ipairs(vim.split(text, "")) do
    self:keys(char == "<" and "<lt>" or char)
  end
end

-- Lets scheduled callbacks and timers run.
function Child:settle(ms) self:lua("vim.wait(...)", ms or 20) end

-- Waits until `code` (a Lua expression) is truthy in the child.
function Child:wait_for(code, ms)
  if not self:lua(("return vim.wait(%d, function() return %s end, 10)"):format(ms or 3000, code)) then
    error("timed out waiting for: " .. code, 2)
  end
end

function Child:set_lines(lines) self:lua("vim.api.nvim_buf_set_lines(0, 0, -1, true, ...)", lines) end
function Child:lines() return self:lua("return vim.api.nvim_buf_get_lines(0, 0, -1, true)") end
function Child:line() return self:lua("return vim.api.nvim_get_current_line()") end
function Child:set_cursor(row, col) self:lua("vim.api.nvim_win_set_cursor(0, { ... })", row, col) end
function Child:cursor() return self:lua("return vim.api.nvim_win_get_cursor(0)") end

-- Writes a file under the child's working directory and returns its path.
function Child:write(name, lines)
  local path = self.work .. "/" .. name
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
  return path
end

function Child:edit(name) self:cmd("edit " .. vim.fn.fnameescape(name)) end

-- Runs a shell command in the child's working directory and environment.
function Child:sh(cmd)
  local result = vim.system({ "sh", "-c", cmd }, { cwd = self.work, env = test_env(self.home), text = true }):wait()
  if result.code ~= 0 then
    error(("sh failed: %s\n%s%s"):format(cmd, result.stdout, result.stderr), 2)
  end
  return vim.trim(result.stdout)
end

function Child:stop() vim.fn.jobstop(self.chan) end

local tests = {}
local current_file = vim.fn.fnamemodify(worker_file, ":t:r")

local function eq(expected, actual, what)
  if not vim.deep_equal(expected, actual) then
    local label = what and (what .. ": ") or ""
    error(("%sexpected %s, got %s"):format(label, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function test(name, fn) table.insert(tests, { name = current_file .. ": " .. name, fn = fn }) end

assert(loadfile(worker_file, "t", setmetatable({ test = test, eq = eq }, { __index = _G })))()

local passed, failed, skipped = 0, {}, 0
for _, t in ipairs(tests) do
  if filter and not t.name:find(filter) then
    skipped = skipped + 1
  else
    local child = Child.new()
    local ok, err = xpcall(t.fn, debug.traceback, child)
    child:stop()
    if ok then
      passed = passed + 1
    else
      table.insert(failed, { name = t.name, err = err })
    end
  end
end

for _, f in ipairs(failed) do
  io.write("FAIL ", f.name, "\n", f.err, "\n\n")
end
io.write(("RESULT %d %d %d\n"):format(passed, #failed, skipped))
vim.fn.delete(root, "rf")
