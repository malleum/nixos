{inputs, ...}: {
  flake.modules.homeManager.wrk = {
    config,
    lib,
    pkgs,
    ...
  }: let
    gitlab = "https://gitlab.visiostack.com";
    mcp = server: map (tool: "mcp__${server}__${tool}");
    bash = map (cmd: "Bash(${cmd})");
    # Claude writes command paths either way, so excludedCommands lists both
    # spellings. Read/Edit rules match the resolved path, so ~/ alone covers
    # them (a single leading / there is relative to ~/.claude; // is absolute).
    home = path: ["~/${path}" "${config.home.homeDirectory}/${path}"];
  in {
    programs.zsh.initContent = ''
      typeset -gA _zsh_abbrs
      _zsh_abbrs=(
        stag 'STAGING_BRANCH=$(git branch --show-current)'
        prod 'VS_RUN_PROD=1'
      )
      _expand_abbr() {
        local word=''${LBUFFER##* }
        if [[ -n ''${_zsh_abbrs[$word]} ]]; then
          LBUFFER=''${LBUFFER%$word}''${_zsh_abbrs[$word]}
        fi
        zle self-insert
      }
      zle -N _expand_abbr
      bindkey ' ' _expand_abbr
      bindkey -M isearch ' ' self-insert
    '';

    # Work sessions run in auto mode (settings.json defaultMode); the sandbox
    # below is currently off. --dangerously-skip-permissions would also skip
    # the GitLab and Sentry write prompts.
    programs.zsh.shellAliases.claude = lib.mkForce "claude";

    claude.mcpServers = {
      GitLab = {
        type = "http";
        url = "${gitlab}/api/v4/mcp";
      };
      Sentry = {
        type = "http";
        url = "https://mcp.sentry.dev/mcp";
      };
    };

    claude.settings = {
      # Claude's git talks to GitLab over HTTPS with the glab token, so it works
      # inside the sandbox: ssh there rejects ~/.ssh/config (a store symlink,
      # so the owner looks wrong) and the proxy does not carry ssh. Only
      # Claude's shells get this; the remotes stay ssh.
      env = {
        GIT_CONFIG_COUNT = "2";
        GIT_CONFIG_KEY_0 = "url.${gitlab}/.insteadOf";
        GIT_CONFIG_VALUE_0 = "git@gitlab.visiostack.com:";
        GIT_CONFIG_KEY_1 = "credential.${gitlab}.helper";
        GIT_CONFIG_VALUE_1 = "!glab auth git-credential";
      };

      # Reads run without asking. Anything that changes GitLab or Sentry
      # always asks, even in auto mode. The names follow the read-gitlab and
      # read-sentry skills in python-code.
      permissions = {
        allow =
          mcp "GitLab" ["get_*" "list_*" "search" "search_labels" "semantic_code_search" "semantic_search"]
          ++ mcp "Sentry" ["find_*" "search_*" "get_sentry_resource"];
        ask =
          mcp "GitLab" ["accept_*" "add_*" "attach_*" "create_*" "delete_*" "fork_*" "link_*" "manage_*" "save_*" "update_*"]
          ++ mcp "Sentry" ["update_*" "analyze_issue_with_seer" "execute_sentry_tool"]
          # glab holds the same token as the MCP server, so its writes ask
          # too. Plain `glab api` GETs stay free; a method or a field makes
          # it a write.
          ++ bash (
            map (c: "glab ${c}:*") [
              "mr create"
              "mr update"
              "mr merge"
              "mr approve"
              "mr close"
              "mr delete"
              "mr note"
              "issue create"
              "issue update"
              "issue close"
              "issue delete"
              "issue note"
              "ci run"
              "ci retry"
              "ci cancel"
            ]
            ++ map (f: "glab api *${f} *") ["-X" "--method" "-f" "-F" "--field" "--raw-field" "--input"]
          )
          # AGENTS.md: never point a command at prod without the developer
          # saying so.
          ++ bash ["*VS_RUN_PROD=*" "*USE_PROD_S3=*"];
        # Merged into the sandbox's denyRead/denyWrite as well, so this covers
        # both the Read/Edit tools and bash. ~/.aws and glab's config stay
        # readable: boto3 and the git credential helper need them.
        deny =
          map (p: "Read(~/${p})") [
            ".ssh/**" # git goes over HTTPS here; the proxy does not carry ssh
            ".gnupg/**"
            ".config/sops/**"
            ".config/gh/**"
            ".local/share/keyrings/**"
            ".claude/.credentials.json"
            ".config/BraveSoftware/**"
            ".config/chromium/**"
            ".mozilla/**"
            ".vs/AWS_IAM_keys.txt"
            ".vs/jhammer.ovpn"
          ]
          ++ ["Read(//run/user/1000/secrets.d/**)"]
          # The clones' .git is writable for worktree commits, but a hook
          # planted there runs outside the sandbox at your next commit.
          # .git/config stays writable (push -u and switch --track need it).
          ++ map (p: "Edit(~/.vs/${p}/.git/hooks/**)") ["python-code" "typescript-code"];
      };

      # Off since 2026-11-09: it blocked the Oracle connection behind CID=…
      # prefixes and pipes, and every GUI/browser launch. Auto mode still
      # checks each command, and the Read deny rules above still cover the
      # Read tool (not bash). The rest is kept so turning it back on is a
      # one-line change.
      sandbox = {
        enabled = false;
        failIfUnavailable = false;
        # No retrying a blocked command outside the sandbox. What really needs
        # out is listed in excludedCommands.
        allowUnsandboxedCommands = false;
        # Still permission-checked, just not sandboxed. A chain leaves the
        # sandbox only when every part matches, and a cd, a redirect, or a
        # wrapper such as `timeout` keeps it in.
        excludedCommands =
          [
            # The nix daemon is a unix socket, which the sandbox blocks.
            "nix:*"
            "nix-shell:*"
          ]
          # Worktrees live directly in ~/.vs, which is not writable, so the
          # python-code-worktrees skill's prune and the -ts sibling need out.
          ++ lib.concatMap (p: ["git -C ${p}/python-code worktree remove:*" "git -C ${p}/typescript-code worktree remove:*" "git -C ${p}/typescript-code worktree add:*"]) (home ".vs")
          # The proxy only carries HTTP(S), not the Oracle connection, so
          # anything that reads the DB needs out: `vs sql`, plugins run
          # locally (`vs run`), and one-off scripts in ~/.vs/local_scripts.
          # A command with a `VAR=value` prefix (CID=10, UV_OFFLINE=1) stays
          # sandboxed whatever is listed here (tested 2026-11-09), so these
          # only help when the CID goes in as a flag (-c 10).
          ++ ["uv run vs sql *" "uv run vs run *"]
          ++ lib.concatMap (s: ["uv run python ${s}/*" "uv run --offline python ${s}/*"]) (home ".vs/local_scripts");
        filesystem.allowWrite = [
          # Worktrees under ~/.vs commit into the canonical clones' .git.
          "~/.vs/python-code/.git"
          "~/.vs/typescript-code/.git"
          # One-off scripts and their outputs (plots, CSVs).
          "~/.vs/local_scripts"
          "~/.cache"
          "~/.local/share/pnpm"
          "~/.local/share/uv"
        ];
        network.allowedDomains = [
          "gitlab.visiostack.com"
          "*.amazonaws.com"
          "pypi.org"
          "files.pythonhosted.org"
          "registry.npmjs.org"
          "github.com"
          "*.githubusercontent.com"
        ];
      };
    };

    home.file.".claude/skills/python-code-worktrees/SKILL.md".source = ./_python-code-worktrees.md;

    home.packages = with pkgs; [
      awscli2
      glab
      gpclient # GlobalProtect VPN
      inputs.fix-python.packages.${pkgs.stdenv.hostPlatform.system}.default
      openvpn
      pnpm # typescript-code; it switches itself to the version package.json pins
      uv
    ];
  };
}
