{inputs, ...}: {
  flake.modules.homeManager.ai = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;
    json = pkgs.formats.json {};
    cfg = config.claude;
    claudeCode = inputs.claude-code.packages.${system}.claude-code;
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
    settingsFragment = json.generate "claude-settings-fragment.json" cfg.settings;
  in {
    options.claude = {
      settings = lib.mkOption {
        inherit (json) type;
        default = {};
        description = ''
          Merged into ~/.claude/settings.json on activation. Claude Code
          rewrites that file itself (/config, /permissions), so it stays a
          plain file: objects merge, lists gain the items they are missing,
          and anything removed here stays there until removed by hand.
        '';
      };
      mcpServers = lib.mkOption {
        type = lib.types.attrsOf json.type;
        default = {};
        description = ''
          User-scope MCP servers, added with `claude mcp add-json` when
          ~/.claude.json does not have them yet. Existing entries are left
          alone so OAuth sign-ins and hand edits survive.
        '';
      };
    };

    config = {
      home.packages = with pkgs; [
        antigravity-cli
        claudeCode
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

      # A broken settings.json or a failed `claude mcp` call only warns: it must
      # not fail the whole switch.
      home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        settings="$HOME/.claude/settings.json"
        current='{}'
        [[ -s $settings ]] && current=$(<"$settings")
        if ! merged=$(printf '%s' "$current" | ${lib.getExe pkgs.jq} --slurpfile want ${settingsFragment} '
          def merge(a; b):
            if (a | type) == "object" and (b | type) == "object" then
              reduce (b | keys_unsorted[]) as $k (a; .[$k] = merge(a[$k]; b[$k]))
            elif (a | type) == "array" and (b | type) == "array" then
              a + (b - a)
            else b end;
          merge(.; $want[0])'); then
          echo "claudeSettings: could not merge into $settings; left as is" >&2
        elif [[ $merged != "$(printf '%s' "$current" | ${lib.getExe pkgs.jq} .)" && ! -v DRY_RUN ]]; then
          mkdir -p "$HOME/.claude"
          printf '%s\n' "$merged" > "$settings.tmp"
          mv "$settings.tmp" "$settings"
        fi

        ${lib.concatStrings (lib.mapAttrsToList (name: server: ''
            if ! ${lib.getExe pkgs.jq} -e --arg n ${lib.escapeShellArg name} '.mcpServers[$n]' "$HOME/.claude.json" >/dev/null 2>&1; then
              run ${claudeCode}/bin/claude mcp add-json --scope user ${lib.escapeShellArg name} ${lib.escapeShellArg (builtins.toJSON server)} \
                || echo "claudeSettings: could not add MCP server ${name}" >&2
            fi
          '')
          cfg.mcpServers)}
      '';
    };
  };
}
