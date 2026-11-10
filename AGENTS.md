## Execution and Git

- For long tasks, maintain the global plan and end goal. Report only material progress. Final handoffs should state the result, validation, remaining risks or work, and any required user input.
- Never force-push unless explicitly asked to rewrite the published history of the specific branch. If a normal push is rejected as non-fast-forward, report it instead of forcing.
- Never merge a pull request or enable auto-merge unless explicitly asked to merge that specific pull request. Green CI, approval, or a request to continue is not merge authorization.
- When commits are requested, keep each commit coherent and reviewable, exclude unrelated changes, and report the commit hash and validation performed.
- Always ask before running `git push`, `git rebase` or a state-changing `gh` CLI operation (e.g. `gh pr create`, `gh pr merge`, `gh issue close`). Read-only `gh` commands such as `gh pr view`, `gh pr diff`, `gh issue view`, and `gh api` GET requests may run without asking.
- Never rewrite existing commits: no `git commit --amend`, no `git commit --fixup`, and no `git rebase -i`/`--autosquash` that would squash, drop, reorder, or reword commits; apply corrections as new commits instead. A plain `git rebase <base>` that replays the branch's commits unchanged onto a new base (e.g. restacking) is allowed under the ask-first rule above. History rewriting is only permitted when the user explicitly asks to reorganize that branch's commits.
- Never read files that are not part of the current Git repository unless they are explicitly requested by the user.
- The user may edit code manually during a session; when a file's content changed externally, disregard prior snapshots and make changes against the latest code.

## Long-running work

- Start slow work (test suites, migrations, container builds, package installs) as a background job, then keep working on independent steps instead of blocking the turn on it.
- Never `sleep` to wait for a job, a test, or a build. Collect results with `job_output`, and use `wait: true` only when nothing else can proceed: it returns as soon as the job settles instead of after a fixed delay.
- Do not cover an operation you could background with a very long command timeout. A timeout should reflect the expected duration of the call itself, not the work behind it.
- Track every job started: collect the still-relevant ones before the final answer and stop the ones that stopped mattering.
- Report progress while work runs rather than only after it finishes.

## Code Style

- Default to writing no comments: reserve them for what is genuinely unclear. Never add a doc comment that only restates a declaration's name or signature; most exported declarations need no comment at all.
- Keep comment lines to at most 120 characters, filling up to the limit before wrapping: wrap at the 120-column boundary, not at 80 or another narrower default. Fold a comment to a single line whenever it fits within 120.
- Never restate "what" the code already says: no mechanism walkthroughs or algorithm steps in declaration docs, and no notes about how other types use this one — that belongs to the other type's own doc.
- Put non-obvious "why" (invariants, assumptions, rationale, failure/retry behavior) in a short comment at the exact code site where the behavior occurs, not in the declaration doc.
- Refer to an identifier in a comment only when it is visible in the same file; otherwise describe the behavior in words and, when a pointer is unavoidable, name the file, so understanding the comment never requires searching the repository.
- A private function or method with exactly one call site deserves a second look: consider inlining it into that caller. Inlining tends to remove parameter plumbing, often lets the helper stop returning what the caller already holds, and makes error handling more direct; length alone is not a reason to extract.
- Keep the helper when the caller would otherwise mix unrelated concerns, or when the helper is what a comment, a test, or a second call site needs.

## Tests

- Cover each behavior at the highest level that can exercise it reliably (API, operation flow, or e2e) instead of duplicating the same coverage in unit tests.
- Reserve unit tests for what higher-level tests cannot exercise deterministically, such as concurrency, atomicity, and race conditions.
- Do not add tests whose only purpose is to assert log field names, field combinations, or structured log payload shape. Logs are operational side effects unless their schema is a documented contract; test the behavior that produces the log instead.
- Do not assert the absence of fields or behavior that never existed; negative assertions should guard a real, previously observed regression.
- Do not add comments to test functions: the test name and its assertions are the documentation.

## Communication

- When an abbreviated technical term (e.g. BFF, CDC, IAM) first appears in a session, add a brief parenthetical expansion on first use — e.g. "BFF (backend for frontend)". Later uses need no explanation; only expand terms the user did not write themselves.

## Chinese

The following words should be avoided in Chinese content, you should replace these words with more easy-to-understand words:
- 锚点
- 接线
- 门禁
- 谓词
- 张力

Besides, avoid figures of speech as much as possible. Using English for professional terms is acceptable.
