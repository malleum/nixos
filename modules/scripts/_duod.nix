# duod: the time of day as a base-12 fraction, and back again. The logic lives
# in _daytime.rs, shared with chron and the jay status bar.
{pkgs, ...}:
pkgs.writers.writeRustBin "duod" {}
(builtins.readFile ./_daytime.rs + builtins.readFile ./_duod.rs)
