{
  unify.modules.ai.home = {pkgs, ...}: {
    home.packages = with pkgs; [
      cursor-cli
      antigravity-cli
      claude-code
      # Jay is not GNOME, so Electron will not auto-pick libsecret. Point
      # Cursor at gnome-keyring (see modules/services/keyring.nix).
      (code-cursor.override {
        commandLineArgs = "--password-store=gnome-libsecret";
      })
      .fhs
    ];
  };
}
