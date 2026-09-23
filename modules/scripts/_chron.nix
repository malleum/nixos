# chron: the time of day in hundredths of a day, and back again. The logic
# lives in _daytime.rs, shared with duod and the jay status bar.
{pkgs, ...}:
pkgs.writers.writeRustBin "chron" {}
(builtins.readFile ./_daytime.rs + builtins.readFile ./_chron.rs)
