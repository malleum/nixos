# ca: launch cursor-agent in a python-code worktree.
#
#   ca                         cursor-agent in the current directory
#   ca <branch> [args...]      cd to ~/.vs/<branch> (create the worktree if
#                              needed) and run cursor-agent; args are passed
#                              through. Flags (ca --resume) stay in the
#                              current directory.
#
# Tab completion with an empty word lists checked-out worktrees only, most
# recently used first (`ca --complete --open`). A prefix lists those first,
# then every other local and origin branch. Each launch inside this repo
# writes an epoch timestamp to $(git rev-parse --absolute-git-dir)/ca-last-used
# so agents can prune worktrees that have not been opened in 14 days.
{pkgs}:
pkgs.writeShellApplication {
  name = "ca";
  runtimeInputs = with pkgs; [coreutils git];
  text = ''
    repo="$HOME/.vs/python-code"

    die() {
      echo "ca: $*" >&2
      exit 1
    }

    require_repo() {
      if [[ ! -e $repo/.git ]]; then
        die "$repo is not a git checkout"
      fi
    }

    # Print the worktree path whose checked-out branch is $1, or return 1.
    worktree_for_branch() {
      local target="refs/heads/$1"
      local path="" line
      while IFS= read -r line || [[ -n $line ]]; do
        case "$line" in
          "worktree "*)
            path=''${line#"worktree "}
            ;;
          "branch "*)
            if [[ ''${line#"branch "} == "$target" ]]; then
              printf '%s\n' "$path"
              return 0
            fi
            ;;
        esac
      done < <(git -C "$repo" worktree list --porcelain)
      return 1
    }

    print_branches() {
      local ref
      git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin \
        | while IFS= read -r ref || [[ -n $ref ]]; do
          ref=''${ref#origin/}
          [[ $ref == HEAD ]] && continue
          printf '%s\n' "$ref"
        done \
        | sort -u
    }

    # "stamp<TAB>branch" for a checkout whose directory still exists.
    open_row() {
      local path="$1" branch="$2" gitdir="" stamp=0
      gitdir=$(git -C "$path" rev-parse --absolute-git-dir 2>/dev/null) || true
      if [[ -n $gitdir && -f $gitdir/ca-last-used ]]; then
        IFS= read -r stamp < "$gitdir/ca-last-used" || stamp=0
      elif [[ -n $gitdir ]]; then
        stamp=$(stat -c %Y -- "$gitdir")
      fi
      printf '%s\t%s\n' "$stamp" "$branch"
    }

    # Open worktrees, newest first. With --open, stop there. Otherwise a "--"
    # line, then every other branch.
    print_complete() {
      local only_open=0
      [[ ''${1-} == --open ]] && only_open=1
      local path="" branch="" line name
      local -a raw=()
      local -A open=()

      remember() {
        [[ -n $branch && -d $path ]] || return 0
        raw+=("$(open_row "$path" "$branch")")
        path=""
        branch=""
      }

      while IFS= read -r line || [[ -n $line ]]; do
        case "$line" in
          "worktree "*)
            remember
            path=''${line#"worktree "}
            branch=""
            ;;
          "branch "*)
            branch=''${line#"branch "}
            branch=''${branch#refs/heads/}
            ;;
          "")
            remember
            ;;
        esac
      done < <(git -C "$repo" worktree list --porcelain)
      remember

      if (( ''${#raw[@]} > 0 )); then
        while IFS= read -r name; do
          [[ -z $name ]] && continue
          open["$name"]=1
          printf '%s\n' "$name"
        done < <(printf '%s\n' "''${raw[@]}" | sort -t $'\t' -k1,1nr -k2,2 | cut -f2-)
      fi

      (( only_open )) && return 0

      printf '%s\n' --

      while IFS= read -r name || [[ -n $name ]]; do
        [[ -n ''${open[$name]+x} ]] && continue
        printf '%s\n' "$name"
      done < <(print_branches)
    }

    valid_branch() {
      case "$1" in
        "" | -* | "." | ".." | "python-code" | /* | *..* | *" "*)
          return 1
          ;;
      esac
    }

    stamp_used() {
      local common gitdir
      common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 0
      [[ $common == "$repo/.git" ]] || return 0
      gitdir=$(git rev-parse --absolute-git-dir 2>/dev/null) || return 0
      date +%s > "$gitdir/ca-last-used"
    }

    add_worktree() {
      local branch="$1" dest="$2" base rc
      mkdir -p -- "$(dirname -- "$dest")"
      if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$repo" worktree add "$dest" "$branch"
      elif git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git -C "$repo" worktree add --track -b "$branch" "$dest" "origin/$branch"
      else
        echo "ca: looking up origin/$branch" >&2
        rc=0
        git -C "$repo" ls-remote --exit-code --heads origin "$branch" >/dev/null || rc=$?
        if [[ $rc -eq 0 ]]; then
          git -C "$repo" fetch --quiet origin "refs/heads/''${branch}:refs/remotes/origin/''${branch}"
          git -C "$repo" worktree add --track -b "$branch" "$dest" "origin/$branch"
        elif [[ $rc -eq 2 ]]; then
          base=master
          git -C "$repo" show-ref --verify --quiet refs/heads/master || base=origin/master
          echo "ca: creating $branch from $base at $dest" >&2
          git -C "$repo" worktree add -b "$branch" "$dest" "$base"
        else
          die "could not look up origin/$branch"
        fi
      fi
    }

    if [[ ''${1-} == --complete ]]; then
      require_repo
      print_complete "''${2-}"
      exit 0
    fi

    if [[ $# -eq 0 || $1 == -* ]]; then
      stamp_used
      exec cursor-agent "$@"
    fi

    branch="$1"
    shift
    valid_branch "$branch" || die "invalid branch name: $branch"
    require_repo

    dest="$HOME/.vs/$branch"
    if path=$(worktree_for_branch "$branch"); then
      if [[ $path != "$dest" ]]; then
        echo "ca: $branch is checked out at $path" >&2
      fi
    else
      if [[ -e $dest ]]; then
        die "$dest exists and is not a worktree for $branch"
      fi
      add_worktree "$branch" "$dest"
      path="$dest"
    fi

    cd "$path" || exit 1
    stamp_used
    exec cursor-agent "$@"
  '';
}
