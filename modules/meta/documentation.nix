{
  unify.nixos = {
    # Disabled for a long stretch because building the man cache dominated
    # switch time. Left commented rather than deleted: with it off, `man -k`
    # and `apropos` do not work. Trying it enabled for a while to see whether
    # the rebuild cost is still bad enough to justify losing them.
    # documentation.man.cache.enable = false;
  };
}
