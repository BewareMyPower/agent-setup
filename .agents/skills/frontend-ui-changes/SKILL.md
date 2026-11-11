---
name: frontend-ui-changes
description: "Change a SvelteKit + TypeScript front end with a short feedback loop: decide against the dependency's source instead of guessing, edit in place instead of rewriting, probe several unknowns in one temporary spec, keep one subgoal per commit, and run the whole browser suite once. Use when modifying a console UI — components, headless widgets (bits-ui), date and range pickers, charts, tables, URL state, form feedback, responsive layout — or when a UI request is ambiguous enough that a wrong guess would cost a rewrite."
---

# Frontend UI Changes

A UI round costs five minutes or thirty depending on the order of work, not on the difficulty of the change. These rules keep the loop short; they come from rounds that guessed at a component library, rewrote a file wholesale, and verified one hypothesis per browser run.

## Decide With Evidence

- Read the dependency's source before designing against it. Headless libraries encode rules in a few functions: `grep` the installed package for the behaviour under question (`node_modules/<pkg>/dist/...`), read it, then design. A six-line sync rule answers in one minute what three failed attempts cannot.
- Timebox any fight with a library to about ten minutes. Past that, pick the design that does not depend on the disputed behaviour (render the widget yourself, or drive the library's own controls) instead of adding workarounds such as forced remounts or synthetic clicks.
- Treat "the widget does not open" as a library question, not a CSS question: check whether the trigger registered, whether the handler is attached, and whether a disabled element can receive the event at all. Probe those facts, do not re-read the template.
- When a request has two plausible readings, ask one short question before writing. Grey-out limits are the classic case: "past the limit is unselectable" and "past the limit switches granularity" produce different code.

## Edit In Place

- Prefer targeted edits over rewriting a working file. A rewrite re-creates solved problems: re-created templates lose behaviour that was already verified, and new `$effect` wiring usually reintroduces the bug the rewrite was meant to avoid.
- In Svelte 5, an `$effect` that reads state it also writes re-runs itself and resets the value the user just set. Read such state through a local `const` inside the effect, or derive the value instead of mirroring it.
- A `$derived` that returns a fresh object notifies on every recomputation, so effects that depend on it re-run for unrelated reasons. Depend on primitives (strings, booleans) and build objects inside the effect.
- Keep one subgoal per commit. Verify it, then layer the next one, so a failure points at one change instead of five.

## Verify Cheapest First

Run the ladder in order and stop at the first failure:

| Step | Command | Cost |
| --- | --- | --- |
| Types and template | `pnpm check` | seconds |
| Format and lint | `pnpm lint` | subsecond |
| Unit and server tests | `pnpm test` | under a minute |
| One browser flow | `pnpm test:browser tests/local/<spec>.ts` | about 20–40 s with the mock server |
| Whole browser suite | `pnpm test:browser` | several minutes |

- Never investigate with the whole suite. Target the spec that covers the change, and run the full suite once before handing off.
- Confirm a suspected pre-existing failure with `git stash` before explaining it as fallout; otherwise a known flaky test looks like a regression and burns a full run twice.
- Probe once, not five times. Write one temporary spec that dumps every unknown in a single run — accessible names, `data-*` state, rendered dates, console output — then delete it. One probe run answering four questions beats four runs answering one each.
- Prove a visual claim with a screenshot from a temporary spec (`page.screenshot({ path, clip })` after the data settles), not with reasoning about classes.
- Leave no residue: delete temporary specs, and restore files a formatter rewrote as a side effect (`git checkout -- src/app.html`) before committing.

## Traps Already Paid For

- `bits-ui` calendars keep the rendered months when a new `placeholder` already falls inside them (`useMonthViewPlaceholderSync` returns early), so assigning the placeholder cannot move the view by one month; forcing a remount then loses to the outgoing instance writing its placeholder back. Drive navigation through the component's own previous and next buttons.
- Chromium dispatches hover to a disabled form control inconsistently, and a headless tooltip built on such a trigger never opens. A hint that must appear on hover belongs on an element that is not disabled.
- A native `title` tooltip has a browser-owned delay that no CSS or JS changes; "the tooltip is slow" is usually a native tooltip, not the app's.
- An empty chart panel in a screenshot may be a screenshot taken before the request settled, not a rendering bug. Wait for the data, then judge.

## Report

- State the subgoal finished, the commands run with their outcome, and anything deliberately left out (a known gap, a deferred clean-up).
- Include a pre-existing failure as a pre-existing failure, with the evidence that it fails without the change.
- When a round runs long because a dependency fought back, say so and name the mechanism; the next round then starts from the answer instead of the guess.
