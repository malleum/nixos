{inputs, ...}: {
  flake.modules.homeManager.wrk = {pkgs, ...}: let
    gitlab = "https://gitlab.visiostack.com";
    mcp = server: map (tool: "mcp__${server}__${tool}");
    bash = map (cmd: "Bash(${cmd})");
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

    # ~/.claude is the work setup (GitLab/Sentry MCPs, work permissions);
    # personal Claude (`cl`, `cld`) gets its own login and history here.
    claude.personalConfigDir = ".claude-personal";

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
      # Claude's git talks to GitLab over HTTPS with the glab token, so it never
      # needs ~/.ssh (denied below). Only Claude's shells get this; the remotes
      # stay ssh.
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
        # ~/ is home, a single leading / is relative to ~/.claude, // is
        # absolute. ~/.aws and glab's config stay readable: boto3 and the git
        # credential helper need them.
        deny =
          map (p: "Read(~/${p})") [
            ".ssh/**" # git goes over HTTPS here
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
          # planted there runs at your next commit, outside Claude's checks.
          # .git/config stays writable (push -u and switch --track need it).
          ++ map (p: "Edit(~/.vs/${p}/.git/hooks/**)") ["python-code" "typescript-code"];
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

  # The machine work happens on day to day, as opposed to one that merely can
  # (wrk alone). Personal `cl`/`cld` ask before opening there, and jay puts
  # the work browser on mod+b (programs/jay/_config.nix).
  flake.modules.homeManager.base = {lib, ...}: {
    options.work.primary = lib.mkEnableOption "the primary work machine (the wrk-primary tag)";
  };
  flake.modules.homeManager.wrk-primary = {
    work.primary = true;
  };
}
