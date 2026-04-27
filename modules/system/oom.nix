{
  unify.modules.gui.nixos = {
    services.earlyoom = {
      enable = true;
      freeMemThreshold = 5;
    };

    zramSwap = {
      enable = true;
      priority = 100;
      # 8GB is plenty for a 64GB machine.
      # It acts as a large buffer for background data.
      memoryMax = 8 * 1024 * 1024 * 1024;
    };
  };
}
