---
name: review
description: "Review code changes against the project's six review criteria. Use for any explicit review request. During implementation, invoke autonomously only for completed changes that are broad or high-risk; skip small, localized, low-risk edits. Do not use for ideas without code changes."
---

# Code Review

Review the requested target against all six criteria below.

## Independent Reviewer

Unless the assignment explicitly identifies the current agent as the context-isolated reviewer, act as the review coordinator:

1. Spawn a fresh subagent with `fork_turns: "none"` so it does not inherit the parent conversation.
2. Identify it explicitly as the context-isolated reviewer. Keep it read-only, tell it to read this skill, and instruct it not to delegate the review again. Require it to assess every equally weighted criterion and use the report format below.
3. Pass only the original requirement or acceptance criteria, the repository path, and the review target such as the working tree, diff, branch, commit, or pull request. Do not pass the parent agent's reasoning, suspected defects, implementation rationale, or draft conclusions. For a follow-up pass, also supply prior findings per "Re-review After Fixes" below.

If the assignment identifies the current agent as the context-isolated reviewer, perform the review directly and do not spawn another subagent or edit files.

After the reviewer returns, report only confirmed findings. For an implementation task, fix them, rerun relevant checks, and repeat the independent review until no findings remain or user direction is needed. For a review-only task, do not edit. If a context-isolated subagent is unavailable, state that the independent review was not completed and do not claim a full review.

## Re-review After Fixes

When the target is a follow-up pass after some earlier findings were addressed:

1. Pass the prior findings to the context-isolated reviewer alongside the requirement and target, and ask it to verify each is resolved. Do not pass how the parent agent judged them or why they were raised.
2. Give the reviewer both diffs it needs: the delta the fixes produced (e.g. working tree vs. the last reviewed commit, or the new commits since the prior pass) and the full review target (e.g. branch vs. base), so it can attribute each new finding to a changed region.
3. Instruct the reviewer to still assess all six criteria across the whole target, not only the fixed regions.

Report each remaining or new finding with an origin label, and name the prior finding or review suggestion that caused it:

- **Introduced by the fix.** The defect sits in a change made to address prior comments, or the fix removed a mechanism the old code had. Attribute it precisely: if the regression traces to a suggestion the previous review made (as opposed to the author's own choice), say so and identify the finding that proposed it — the flaw is in the suggestion, not in how it was applied.
- **Pre-existing (previously missed).** The defect was already present in the reviewed code before the fixes and was not reported earlier.

Do not relist resolved prior findings; one summary line in the `### Review summary` noting which were confirmed resolved is enough. Keep the six criterion sections and report format unchanged otherwise.

## Review Criteria

Treat all six criteria as independent and equal in importance. Their order is not a priority ranking. Correctness is neither a gate nor the default focus: do not stop or abbreviate the other assessments after checking it.

1. **Problem and approach:** Verify the problem is valid, the approach is the simplest adequate solution, and the stated reasoning explains why the approach solves the problem.
2. **Correctness:** Check behavior, edge cases, failure handling, concurrency, and relevant invariants.
3. **Test value:** Require every committed test and benchmark to earn its long-term maintenance cost.
   - Request new coverage only after identifying the concrete regression and explaining why existing checks cannot catch it; a production code change alone is not justification.
   - For every added or modified case, first consider deletion or consolidation. Keep it only when its distinct regression protection justifies the maintenance cost.
   - Prefer stable, high-level behavior tests. Do not duplicate lower-level unit coverage when a behavior test already protects the same contract.
   - Avoid asserting literals, declarative mappings, obvious control flow, or implementation details. Do not introduce fakes, fixtures, or test-only abstractions whose complexity outweighs the behavior they protect.
   - Apply the same standard to benchmarks: tie every checked-in case to a credible long-term regression. Keep PR-specific A/B benchmark cases temporary and out of the repository.
4. **Linear flow:** Simplify control flow, remove unnecessary indirection, and keep the main execution path direct.
5. **Net line reduction:** Look for opportunities to remove code or solve the problem with fewer net lines without weakening clarity or correctness.
6. **Project consistency:** Check module placement, item ordering, naming, and whether each comment is necessary against nearby project conventions.

## Report Format

Begin with a `### Review summary` section. Make it concise but substantive enough to demonstrate an independent understanding of the change. Explain:

1. The user-visible or operational problem and the intended outcome. State why the change is needed; a list of new APIs, types, or behaviors is not the purpose.
2. The material behavior or design changes, rather than a file-by-file inventory.
3. The causal chain from those changes to the intended outcome, and why the chosen approach is the simplest adequate solution given existing project mechanisms, relevant constraints, and material alternatives.

Do not reduce the summary to what changed or merely repeat the author's rationale. Make it self-contained enough that a reader can understand the goal and design without the change description. Replace unsupported conclusions such as "the approach is reasonable" with concrete reasoning, for example which invariant is preserved, which source of truth stays shared, or which duplication or complexity is avoided.

Verify that reasoning against the target. When an approach is directionally sound but incomplete, distinguish the sound design choice and its benefit from the missing mechanism and its consequence. If the approach does not solve the stated problem, cannot be justified as the simplest adequate solution, or leaves an important tradeoff unresolved, summarize that limitation and report the actionable concern under **Problem and approach**.

After the summary, add one findings section for each review criterion, using the exact headings and order below:

```markdown
### Problem and approach

### Correctness

### Test value

### Linear flow

### Net line reduction

### Project consistency
```

Under each heading, list only actionable findings, ordered by severity, with file and line references where applicable. Format every finding as a bullet beginning with a bold priority and concise actionable title, such as `- **[P1] Serialize catalog writes.**`, followed by the concrete behavior, impact, evidence, and required direction. Do not leave findings unlabeled. If a criterion has no findings, write `No findings.` Do not omit or merge empty criteria; the summary does not replace the **Problem and approach** findings section.

Do not add dedicated validation or verdict sections by default. Report a validation gap only when the user requests validation details or the gap creates an actionable concern; in the latter case, place it under the relevant review criterion. When useful, finish with a single unheaded verdict sentence. State the verdict only once; do not repeat it in both the summary and the closing sentence. Omit routine review mechanics, successful check lists, CI status, and temporary workspace details unless the user asks for them or a failure affects confidence in the review.
