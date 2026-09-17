-- Multiple cursors. Each step is a key sequence; strings starting with ":"
-- are typed one character at a time (insert-mode text).

local function scenario(name, lines, steps, expected)
  test(name, function(c)
    c:set_lines(lines)
    c:set_cursor(1, 0)
    for _, step in ipairs(steps) do
      if step:sub(1, 1) == ":" then
        c:type(step:sub(2))
      else
        c:keys(step)
      end
    end
    c:settle()
    eq(expected, c:lines())
  end)
end

scenario(
  "<C-n> three matches, c changes all",
  { "foo a", "foo b", "foo c", "food" },
  { "<C-n>", "<C-n>", "<C-n>", "c", ":bar", "<Esc>" },
  { "bar a", "bar b", "bar c", "food" }
)
scenario(
  "q skips a match",
  { "foo 1", "foo 2", "foo 3" },
  { "<C-n>", "n", "q", "c", ":X", "<Esc>" },
  { "X 1", "foo 2", "X 3" }
)
scenario(
  "Q removes one, a appends",
  { "id id id" },
  { "<C-n>", "n", "n", "Q", "a", ":_x", "<Esc>" },
  { "id_x id_x id" }
)
scenario(
  "two matches on one line",
  { "x = foo + foo" },
  { "4l", "<C-n>", "n", "c", ":bar", "<Esc>" },
  { "x = bar + bar" }
)
scenario("N adds the previous match", { "w1 w w2 w" }, { "$", "<C-n>", "N", "c", ":9", "<Esc>" }, { "w1 9 w2 9" })
scenario("i inserts before every selection", { "ab ab" }, { "<C-n>", "n", "i", ":_", "<Esc>" }, { "_ab _ab" })
scenario(
  "charwise visual <C-n> matches inside words, d",
  { "xab xab ab" },
  { "l", "vl", "<C-n>", "n", "n", "d" },
  { "x x " }
)
scenario(
  "linewise visual <C-n>: A on every line",
  { "a", "bb", "ccc" },
  { "Vjj", "<C-n>", "A", ":,", "<Esc>" },
  { "a,", "bb,", "ccc," }
)
scenario(
  "blockwise visual <C-n> at a column",
  { "abcd", "abcd", "abcd" },
  { "l", "<C-v>jj", "<C-n>", "i", ":-", "<Esc>" },
  { "a-bcd", "a-bcd", "a-bcd" }
)
scenario("<C-Down> twice, x", { "abc", "abc", "abc" }, { "<C-Down>", "<C-Down>", "x" }, { "bc", "bc", "bc" })
scenario(
  "<C-Up> from the bottom, I",
  { "x", "  y", "z" },
  { "G", "<C-Up>", "<C-Up>", "I", ":#", "<Esc>" },
  { "#x", "  #y", "#z" }
)
scenario(
  "one u undoes the change everywhere",
  { "foo", "foo" },
  { "<C-n>", "n", "c", ":Z", "<Esc>", "u" },
  { "foo", "foo" }
)
scenario("edits in a row", { "a", "a" }, { "<C-Down>", "A", ":1", "<Esc>", "A", ":2", "<Esc>" }, { "a12", "a12" })
scenario(
  "after an edit, selections are cursors: ciw",
  { "foo x", "foo y" },
  { "<C-n>", "n", "c", ":ab", "<Esc>", "ciw", ":ZZ", "<Esc>" },
  { "ZZ x", "ZZ y" }
)
scenario(
  "<Esc> stops: later edits are single",
  { "a", "a" },
  { "<C-Down>", "<Esc>", "A", ":b", "<Esc>" },
  { "a", "ab" }
)
scenario(
  "change, append, then x",
  { "one two", "one two" },
  { "<C-n>", "n", "c", ":uno", "<Esc>", "A", ":!", "<Esc>", "0", "x" },
  { "no two!", "no two!" }
)

-- Motions
scenario(
  "motion: w then x",
  { "a b c", "a b c", "a b c" },
  { "<C-Down>", "<C-Down>", "w", "x" },
  { "a  c", "a  c", "a  c" }
)
scenario(
  "motion: e then a",
  { "foo bar", "foo baz" },
  { "<C-n>", "n", "e", "a", ":!", "<Esc>" },
  { "foo! bar", "foo! baz" }
)
scenario(
  "motion: $ on lines of different lengths",
  { "ab", "abcd", "abcdef" },
  { "<C-Down>", "<C-Down>", "$", "x" },
  { "a", "abc", "abcde" }
)
scenario("motion: f, then x", { "a,b", "aa,bb", "aaa,bbb" }, { "Vjj", "<C-n>", "f,", "x" }, { "ab", "aabb", "aaabbb" })
scenario(
  "motion: 2w then cw",
  { "x one two", "x uno dos" },
  { "<C-Down>", "2w", "cw", ":Z", "<Esc>" },
  { "x one Z", "x uno Z" }
)
scenario("motion: j moves every cursor", { "a", "b", "c", "d" }, { "<C-Down>", "j", "x" }, { "a", "", "", "d" })
scenario(
  "motion: ] only moves between cursors",
  { "a1", "a2", "a3" },
  { "<C-Down>", "<C-Down>", "]", "x" },
  { "1", "2", "3" }
)

test("multicursor loads on first use", function(c)
  eq(false, c:lua([[return package.loaded["mvim.multicursor"] ~= nil]]))
  c:set_lines({ "foo foo" })
  c:keys("<C-n>")
  eq(true, c:lua([[return package.loaded["mvim.multicursor"] ~= nil]]))
end)

test("keys typed right after <Esc> wait for the replay", function(c)
  c:set_lines({ "foo x", "foo y" })
  c:keys("<C-n>")
  c:keys("n")
  c:keys("c")
  c:type("ab")
  -- One burst: the replay of the first edit must run before ciw starts.
  c:keys("<Esc>ciwZZ<Esc>")
  c:settle()
  eq({ "ZZ x", "ZZ y" }, c:lines())
end)
