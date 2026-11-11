{inputs, ...}: {
  flake.modules.homeManager.ai = {
    config,
    lib,
    pkgs,
    hostConfig,
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

    # cl / cld: personal Claude, kept apart from the work setup (`ca`, plain
    # `claude`) by CLAUDE_CONFIG_DIR when personalConfigDir is set. On the
    # primary work machine they ask first, in case `ca` was meant.
    #
    # Inside teno the tab bar shows the foreground program's argv[0], so the
    # launch dir goes there: argv[0] becomes `claude:<name>/<dir>`. teno shows
    # the part after the last `/`, and its restore rules (programs/teno.nix)
    # match the `claude:<name>/` prefix to relaunch with `<name> --continue`.
    # CLAUDE_SKIP_WORK_CHECK=1 skips the question (teno sets it on restore).
    personal = name: extraArgs:
      pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [pkgs.coreutils];
        text = ''
          ${lib.optionalString (cfg.personalConfigDir != null) ''
            export CLAUDE_CONFIG_DIR="$HOME/${cfg.personalConfigDir}"
          ''}
          ${lib.optionalString config.work.primary ''
            if [[ -z ''${CLAUDE_SKIP_WORK_CHECK-} && -t 0 ]]; then
              read -r -p "This is ${hostConfig.name}. Open this agent, not ca? [y/N] " reply
              [[ $reply == [yY]* ]] || exit 1
            fi
          ''}
          unset CLAUDE_SKIP_WORK_CHECK
          if [[ -n ''${TENO-} ]]; then
            if [[ $PWD == "$HOME" ]]; then label="~"; else label=$(basename -- "$PWD"); fi
            exec -a "claude:${name}/$label" ${claudeCode}/bin/claude ${lib.escapeShellArgs extraArgs} "$@"
          fi
          exec ${claudeCode}/bin/claude ${lib.escapeShellArgs extraArgs} "$@"
        '';
      };
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
      personalConfigDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = ".claude-personal";
        description = ''
          Config dir for `cl`/`cld`, relative to home. Null: they share
          ~/.claude with plain `claude`.
        '';
      };
    };

    config = {
      home.packages = with pkgs; [
        antigravity-cli
        claudeCode
        claudeDesktop
        (personal "cl" [])
        (personal "cld" ["--dangerously-skip-permissions"])
      ];

      programs.zsh.shellAliases.clauded = "cld";

      # Escape is for vim mode, not for cancelling a running turn (ctrl+c still
      # interrupts).
      home.file = let
        keybindings.text = builtins.toJSON {
          "$schema" = "https://www.schemastore.org/claude-code-keybindings.json";
          "$docs" = "https://code.claude.com/docs/en/keybindings";
          bindings = [
            {
              context = "Chat";
              bindings.escape = null;
            }
          ];
        };
      in
        {".claude/keybindings.json" = keybindings;}
        // lib.optionalAttrs (cfg.personalConfigDir != null) {
          "${cfg.personalConfigDir}/keybindings.json" = keybindings;
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
