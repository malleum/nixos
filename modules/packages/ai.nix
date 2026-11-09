{inputs, ...}: {
  flake.modules.homeManager.ai = {pkgs, ...}: let
    inherit (pkgs.stdenv.hostPlatform) system;
    # XDG_CURRENT_DESKTOP is `jay`, so Electron falls back to `basic` and
    # Claude warns "No system keyring is available" (see
    # modules/services/keyring.nix). The upstream launcher passes
    # --password-store from this var.
    claudeDesktop = pkgs.symlinkJoin {
      name = "claude-desktop";
      paths = [inputs.claude-desktop.packages.${system}.claude-desktop-fhs];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/claude-desktop \
          --set CLAUDE_PASSWORD_STORE gnome-libsecret
      '';
    };
  in {
    home.packages = with pkgs; [
      antigravity-cli
      inputs.claude-code.packages.${system}.claude-code
      claudeDesktop
    ];

    # Escape is for vim mode, not for cancelling a running turn (ctrl+c still
    # interrupts).
    home.file.".claude/keybindings.json".text = builtins.toJSON {
      "$schema" = "https://www.schemastore.org/claude-code-keybindings.json";
      "$docs" = "https://code.claude.com/docs/en/keybindings";
      bindings = [
        {
          context = "Chat";
          bindings.escape = null;
        }
      ];
    };
  };
}
