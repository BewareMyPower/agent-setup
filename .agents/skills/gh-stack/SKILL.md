---
name: gh-stack
description: "Work safely in repositories whose branches are managed as a stacked-PR chain by the `gh stack` GitHub CLI extension (commonly aliased `gs`). Use when the user runs `gs`/`gh stack` commands, mentions stacked PRs or restacking, asks to resolve rebase conflicts while a `gh stack` operation is paused, or when `.git/gh-stack` exists. Covers the rule that prevents snapshot desync (never run plain `git rebase` mid-operation), recovery when branch refs and the recorded state disagree, and normal stack commands. Not for Graphite `gt` or git spr."
---

# gh stack (`gh stack`, often aliased `gs`)

`gh stack` manages a chain of branches L1→L2→…→Ln as stacked PRs. It records each branch's `head` and `base` SHA plus its PR in `.git/gh-stack`, and snapshots every tip when a mutating operation starts. Plain `git` still works, but mixing it with an in-flight `gs` operation is the main failure mode.

Detect a gh-stack repo by `.git/gh-stack`, refs under `.git/refs/stack-backup/`, or the user mentioning `gs`/`gh stack`.

## The rule that prevents desync

When `gs rebase` pauses on a conflict, the gs operation is still open and its snapshot of all branch tips is live.

- Resolve files, `git add` them, then run `gs rebase --continue`. Let gs finish its own cascade through the remaining branches.
- Never run `git rebase --continue`, `git rebase --abort`, `git rebase --skip`, `git rebase` anew, or `git branch -f` on any stack branch while the operation is paused. Completing the underlying git rebase behind gs's back leaves its snapshot stale; the next `gs rebase --continue` can reset a branch back to the snapshot SHA and silently drop already-rebased work, or refuse with `changed since this operation's snapshot`.
- Never manually rebase downstream branches mid-operation. If downstream tips legitimately moved (someone else rebased them), expect the snapshot-mismatch refusal and go to Recovery.
- To abandon the operation entirely, prefer `gs rebase --abort` (restores the snapshot) over dismantling git state by hand.

## Recovery: refs and gs state disagree

Symptoms: `gh stack view` shows a broken chain, `merge-base` ancestry fails between adjacent layers, or gs refuses with `changed since this operation's snapshot`.

1. Fix the refs with plain git first. For each layer verify `git merge-base --is-ancestor <parent-branch> <child-branch>`. If a branch points at a stale tip, find the correct tip — it is usually still reachable as an ancestor of the downstream branch that was rebased onto it: `git merge-base --is-ancestor <candidate-sha> <downstream-branch>`. Then `git branch -f <branch> <sha>` (only when not checked out).
2. Re-sync the recorded state: `gh stack rebase --no-trunk`. It checks each layer contains the previous layer's tip (no-op where already correct) and rewrites `.git/gh-stack` head/base to the real SHAs. Do this before any other gs command — a stale recorded `base` makes the next restack replay the wrong commit range and can duplicate upstream commits inside downstream branches.
3. Verify `gh stack view` shows the full chain and per-layer ancestry passes.

## Normal operations

- `gh stack view` renders the chain and PR links from live refs; it is the quickest sanity check.
- `gh stack rebase` (no flag) fetches the trunk and rebases the bottom layer too; `--no-trunk` performs only inter-branch checks. Prefer `--no-trunk` when the trunk position must not move.
- `gh stack push` force-pushes every stack branch and updates the PR base chain. Do not `git push` individual stack branches — PR bases are gs-managed.
- `gh stack rebase --upstack` / `--downstack` limits the cascade to one direction from the current branch.
- Other: `add`, `modify`, `submit`, `sync`, `checkout`, `unstack`, and `bottom`/`down`/`up`/`top`/`trunk` navigation.

## Stuck git-level rebase inside a gs pause

If `git status` says "all conflicts fixed" but `git rebase --continue` errors `you have staged changes in your working tree`, the sequencer state desynced (e.g. a killed editor or a stale `.git/MERGE_RR.lock`). Check `.git/rebase-merge/done` for the attempted pick, then `git commit -C <original-sha>` to commit the staged resolution with the original message, then `gs rebase --continue` — not `git rebase --continue`, per the desync rule above.

## Notes

- Conflicts recur across restacks (changelog and README paragraphs move with every layer). Keep `rerere` enabled so repeat resolutions auto-apply.
- `.git/refs/stack-backup/` holds pre-operation backup refs; inspect it before force-moving anything during recovery.
- `git rerere` plus the recovery steps above mean no resolution work is truly lost — prefer repair over `reset --hard` to a remote ref.
