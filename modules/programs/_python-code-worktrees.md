---
name: python-code-worktrees
description: >-
  Manage python-code git worktrees under ~/.vs. Use at the start of a session
  in ~/.vs/python-code or any linked worktree of that repo, and whenever the
  user mentions ca, worktrees, pruning, or which checkout to use. Prune stale
  worktrees and tell the user to launch feature work with `ca <branch>`.
---

# python-code worktrees

`ca` owns checkout creation. Do not create worktrees yourself (no `--worktree` or EnterWorktree), and do not check a feature branch out in the primary clone.

## Layout

- Primary clone: `~/.vs/python-code`. Leave it on `master`.
- Feature checkout: `~/.vs/<branch>`. `ca <branch>` cds there, creating the worktree when it is missing, then runs `claude`. Extra arguments are passed through to `claude`. `ca` with no arguments, or `ca` followed by a flag, runs `claude` in the current directory.
- A branch that already exists locally or on `origin` is checked out as-is. A name origin does not have is created from `master`.
- Frontend work for a branch lives in a typescript-code worktree, either `<checkout>/typescript-code` (from `uv run vs monorepo typescript-code ensure`, see the read-typescript-code skill) or a sibling `~/.vs/<branch>-ts`. `ca` adds the sibling with `--add-dir` when it exists. To make a missing sibling, run `git -C ~/.vs/typescript-code worktree add ~/.vs/<branch>-ts …` (same branch rules as `ca`), then ask the user to run `/add-dir ~/.vs/<branch>-ts` so this session can write to it.
- `~/.vs` itself is outside the sandbox's writable paths. `git -C ~/.vs/python-code worktree remove …` and `git -C ~/.vs/typescript-code worktree {add,remove} …` are excluded from the sandbox, but only when run exactly in that form: no `cd`, no redirects, and every part of a `&&` chain must be one of them. Run each as its own command.
- Each `ca` launch in this repo writes an epoch timestamp to `$(git rev-parse --absolute-git-dir)/ca-last-used`.

Do not put checkouts in `/tmp`, `.claude/worktrees` or `~/.cursor/worktrees`.

## Start of session

Do this before other work when `git rev-parse --path-format=absolute --git-common-dir` is `~/.vs/python-code/.git`. Then continue the task in the current directory.

### Where this session is

Compare the toplevel with `~/.vs/<branch>` for `git branch --show-current`.

- Already there, or the primary clone is on `master`: say nothing about location.
- Anywhere else: one sentence telling the user to quit and run `ca <branch>`. Do not move the branch unless they ask. If the branch is locked in the primary clone, say that `ca <branch>` keeps opening `~/.vs/python-code` until that clone is clean and back on `master`.

### Prune

1. Run `git -C ~/.vs/python-code worktree prune`. That drops registrations whose directory is already gone. It does not delete checkouts that still exist.
2. For every remaining worktree from `git -C ~/.vs/python-code worktree list --porcelain`, skip `~/.vs/python-code` and skip this session's toplevel.
3. Remove a worktree only when `git -C <path> status --porcelain` is empty and either:
   - `git -C <path> merge-base --is-ancestor HEAD origin/master` succeeds (do not fetch), or
   - it was last used at least 14 days ago and it has no commits missing from both `origin/master` and its upstream.
4. Last used is the integer in `<absolute-git-dir>/ca-last-used`. If that file is missing, use `stat -c %Y` on the absolute git dir. 14 days is 1209600 seconds before `date +%s`.
5. Its typescript worktree is `<worktree>/typescript-code` when that `.git` is a file, or `~/.vs/<branch>-ts` when it exists. When it is clean, remove it first with `git -C ~/.vs/typescript-code worktree remove <path>`. If it is dirty, skip the python worktree too.
6. Use `git worktree remove` with no `--force`. On failure, leave it and say why.
7. Do not delete branch refs.

Mention a path only when you removed it, or when you kept it because it was dirty or had commits that are not on a remote. If neither happened, say nothing about pruning.

## Environment

If the worktree has no `.venv`, run `UV_OFFLINE=1 uv sync --all-extras --inexact` there before tests or `uv run`. If that fails because the cache is missing a package, rerun without `UV_OFFLINE=1`.

For commands run in the worktree, `STAGING_BRANCH` is that worktree's branch name.
