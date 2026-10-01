{
  flake.modules.homeManager.ai = {
    pkgs,
    lib,
    ...
  }: let
    # Cursor's Linux sandbox tmpfs-mounts /run, which hides
    # /run/current-system/sw/bin/zsh (NixOS's default $SHELL). Point SHELL at
    # the store path so cursorsandbox can exec the shell; /nix/store stays
    # visible inside the sandbox.
    cursorCli = pkgs.symlinkJoin {
      name = "cursor-cli";
      paths = [pkgs.cursor-cli];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/cursor-agent \
          --set SHELL ${lib.getExe pkgs.zsh}
      '';
    };
  in {
    home.packages = with pkgs; [
      cursorCli
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
