{inputs, ...}: {
  flake.modules.homeManager.ai = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;
    # Cursor's Linux sandbox tmpfs-mounts /run, which hides
    # /run/current-system/sw/bin/zsh (NixOS's default $SHELL). Point SHELL at
    # the store path so cursorsandbox can exec the shell; /nix/store stays
    # visible inside the sandbox.
    #
    # patchelf 0.19 (nixpkgs unstable) writes overlapping LOAD
    # headers into this package's node, and ld.so segfaults. 0.15 from stable
    # does not. The September tarball breaks the same way under 0.19, so the
    # pin that works is the current tarball built with the older patchelf.
    # Drop the preFixup once `.../share/cursor-agent/node --version` works
    # without it.
    cursorCliPkg = pkgs.cursor-cli.overrideAttrs (old: {
      preFixup = ''
        export PATH="${pkgs.stable.patchelf}/bin:$PATH"
      '';
    });
    cursorCli = pkgs.symlinkJoin {
      name = "cursor-cli";
      paths = [cursorCliPkg];
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
      inputs.claude-desktop.packages.${system}.claude-desktop-fhs
      # Jay is not GNOME, so Electron will not auto-pick libsecret. Point
      # Cursor at gnome-keyring (see modules/services/keyring.nix).
      (code-cursor.override {
        commandLineArgs = "--password-store=gnome-libsecret";
      })
      .fhs
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
