---
name: gh-stack
description: "Work safely in repositories whose branches are managed as a stacked-PR chain by the `gh stack` GitHub CLI extension (commonly aliased `gs`). Use when the user runs `gs`/`gh stack` commands, mentions stacked PRs or restacking, asks to resolve rebase conflicts while a `gh stack` operation is paused, or when `.git/gh-stack` exists. Covers the rule that prevents snapshot desync (never run plain `git rebase` mid-operation), how to rewrite a lower layer and replay the rest of the chain, the build gate that stops a broken commit entering history, per-tip validation and PR-text refresh after pushing, recovery when branch refs and the recorded state disagree, and normal stack commands. Not for Graphite `gt` or git spr."
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

## Changing a lower layer, then replaying the chain

Rewriting L1 (a renamed helper, a dropped column, a changed DTO field) makes every upper layer a candidate for conflicts *and* for silent breakage. Plan for it before starting the rebase.

1. **Inventory the breakage first.** Grep every upper tip for what the change removed or renamed, so surprises become planned edits: `git grep -n '<symbol>' <L2> <L3> <L4>` (`git branch --list` lists the names). Include test helpers and fixtures, column names, constructor parameters, and DTO fields — a helper that no longer exists compiles fine in the diff but breaks the upper layer's tests.
2. **Resolve each pause in one pass.** Read every conflicted file the pause lists, decide all resolutions, then run the gate below. Do not resolve one file, continue, and discover the next three.
3. **Gate every `--continue` on a full build.** gs commits exactly what is staged, so a tree that does not compile becomes a commit that does not compile. Run `gofmt -l <changed dirs>`, `go build ./...`, `go vet ./internal/...` (or the repo's equivalent), and only then stage and `gh stack rebase --continue`. A broken commit costs a fix commit on that layer, another `gs rebase` to propagate it, and a second round of the same conflicts — the single largest time sink in a restack.
4. **Adapt deliberately.** When an upper layer must change to fit the new lower layer (drop a removed fallback, read an id as a string), commit that on that layer as its own small commit whose subject says what was adapted, and add one PR bullet so a reviewer knows why the commit exists. Never fold the adaptation into an unrelated commit, and never amend (global rules).
5. Expect four to six pauses on a four-layer stack (changelog and README paragraphs conflict on every layer). That is normal; the desync rules above still apply throughout.

## Validate and publish the cascade

- **Pick packages by the diff, not `./...` on every tip.** Only packages the change touches, plus the top tip's full suite when CI is the gate. A full suite on every branch usually dominates the wall clock while adding no information: the lower-layer code is identical across tips.
- **Run the tips in parallel as background jobs** (one per branch), and use the wait to draft PR text or verify the sibling repo. Never park the turn on `sleep`, and never block on a test loop that could have been independent jobs.
- **Verify the push.** After `gh stack push`, compare each local tip with `git ls-remote origin <branch>`; gs force-pushes every layer, and a silent mismatch means a layer is behind.
- **Refresh the PR text.** A body written before the change often states behavior the branch no longer has (a removed header, an old retry rule, a "refuses to" that now replays). Sweep every body for sentences the change made false, and add the "adapted to layer N" bullet to each upper PR.
- **Land the sibling repo in the same pass.** A stack that changes an HTTP contract has a consumer (console, admin, CLI) that must be verified, committed, pushed, and given its own PR bullet before the work is done.

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
- Never pipe `go build`, `go vet`, or test output through `head`: the errors that matter are further down, and the command has to be re-run.
- A stale `.git/MERGE_RR.lock` can block a plain `git commit` even with no rebase in progress. Confirm no git process is running, then delete the lock.
- After a commit or `--continue` fails, check `git log` and `git status` before retrying: a series is often partially applied, and re-running the whole staging step can misplace later changes.
