# The Rust coreutils shadow GNU's in PATH. Deliberately user-scope only:
# putting them in environment.systemPackages would shadow GNU coreutils for
# root and for system units too, which is a much wider blast radius than
# intended for a reimplementation.
{
  unify.home = {pkgs, ...}: {
    home.packages = [pkgs.uutils-coreutils-noprefix];
  };
}
