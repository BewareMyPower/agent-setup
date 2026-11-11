# Global agent config

My personal global setup for coding agents, reused on every machine: shared instructions, skills, and Pi configuration.

| Path               | Contents                                                          |
| ------------------ | ----------------------------------------------------------------- |
| `AGENTS.md`        | Global instructions applied to every session.                     |
| `.agents/skills/`  | Global skills.                                                    |
| `.agents/agents/`  | Subagent definitions used by the skills.                          |
| `pi/settings.json` | Pi user settings: theme, default model, thinking level, packages. |
| `pi/open-tui.json` | Footer and interface options for the `pi-open-tui` extension.     |
| `pi/agents/`       | Pi subagent definitions, linked into `~/.pi/agent/agents`.        |
| `pi/setup.sh`      | Bootstrap for a fresh machine.                                    |

## Fresh machine

Prerequisites: Node.js with `pi` installed (`npm i -g @earendil-works/pi-coding-agent`), and a terminal font that can draw the footer icons (see [Terminal icons](#terminal-icons)).

```sh
git clone https://github.com/BewareMyPower/agent-setup.git
cd agent-setup
./pi/setup.sh
pi auth login deepseek
```

Repeat `pi auth login <provider>` for every provider you use; credentials are never stored in this repository.

`setup.sh` writes `pi/settings.json` and `pi/open-tui.json` into the agent directory (`$PI_CODING_AGENT_DIR`, default `~/.pi/agent`) only when those files are missing, symlinks `AGENTS.md` as both `~/.pi/agent/AGENTS.md` and `~/.agents/AGENTS.md`, links `.agents/skills/*` and `.agents/agents` into `~/.agents`, links `pi/agents/*.md` into `~/.pi/agent/agents`, and finishes with `pi update --extensions` to install the packages declared in `settings.json`. Pass `--force` to replace existing files; their previous contents are kept as `<file>.bak.<timestamp>`.

Both `AGENTS.md` links matter: Pi reads user instructions only from the agent directory (`~/.pi/agent/AGENTS.md`) and from `AGENTS.md` in the working directory or one of its ancestors, while `~/.agents/AGENTS.md` is the location other agents such as the DeepSeek harness read. Deleting the agent-directory copy silently drops the global instructions from Pi.

Instructions and skills stay authoritative here: edit them in this repository and every machine picks the change up through the symlink. The two `pi/*.json` files are copies, so after changing a setting through `/settings` or `/open-tui` on any machine, copy that file back here and commit it.

Not committed on purpose: `auth.json` (API keys and OAuth tokens), `trust.json` and `trust/` (per-machine trust decisions keyed by absolute path), `sessions/`, `models-store.json` (regenerated model catalog cache), and the `npm/` and `git/` package installs.

## Subagents

Pi ships no subagent tool, so the `pi-subagents` package in `settings.json` provides one: a `subagent` tool that runs a child Pi session with its own context window, builtin `scout`, `researcher`, `worker`, `reviewer`, `oracle`, and `delegate` agents, parallel and chained runs, and background children. It is what the `review` skill means by an independent review — ask for it directly ("use reviewer to review this diff") and the child never sees the parent transcript.

Agent files are markdown with YAML frontmatter (`name`, `description`, `tools`, optional `model` and `thinking`) read from `~/.pi/agent/agents/**/*.md` in this setup, with project agents from `.pi/agents/**/*.md` behind project trust. `pi/agents/comment-sicko.md` is linked there by `setup.sh`; it is a Pi-format port of `.agents/agents/comment-sicko.md`, whose `mode: subagent` frontmatter belongs to another agent runtime, so the two files are kept in sync by hand.

## Reading the transcript

`Ctrl+T` collapses or expands thinking blocks and saves the choice as `hideThinkingBlock`, and `thinkingPeek.lines` in `open-tui.json` keeps the last one or two lines of live reasoning visible while hidden.

`Ctrl+O` collapses tool *results* only, so a tool whose arguments are long, such as a `bash` command with an inline heredoc, still fills the screen while collapsed. `toolView.mode: "compact"` is what shortens the call itself into one summary row per tool, and `toolView.exclude` keeps the native card for named tools. Compact mode applies to rows created after `/reload` or a new session.

## Terminal icons

Symptom: the footer shows boxed `?` marks where icons should be, next to the branch, runtime, context bar, token counts, cache rate, and cost.

Those marks are Nerd Font glyphs from the Unicode private use area, and the terminal font has no glyph for them. With `icons.mode: "auto"`, `pi-open-tui` picks ASCII only when stdout is not a TTY, `TERM=dumb`, or the first configured locale (`LC_ALL`, `LC_CTYPE`, `LANG`) is not UTF-8, and Unicode only when `SSH_TTY` or `SSH_CONNECTION` is set. Everywhere else it selects Nerd Font glyphs without inspecting the installed fonts, so a local session with Monaco, Menlo, or SF Mono renders a notdef box for each one. The same missing glyph is why those characters get stripped when the footer is copied into a chat message.

Fix it by either installing a patched font and selecting it in the terminal profile:

```sh
brew install --cask font-jetbrains-mono-nerd-font
# iTerm2: Settings → Profiles → Text → Font → JetBrainsMono Nerd Font
printf '\ue0a0 \ue5ff \uf015 \U000f0179\n'
```

The installed files are named `JetBrainsMonoNF-Regular.ttf` and similar, while pickers list the family as `JetBrainsMono Nerd Font`, so a profile that reads back as `JetBrainsMonoNF-Regular 12` is already correct.

or by dropping the glyphs entirely: set `"icons": { "mode": "unicode" }` in `~/.pi/agent/open-tui.json` (`ascii` for plain text), or cycle the value under Appearance → Icons in the `/open-tui` dialog. Unicode mode falls back to the terminal's emoji and symbol fonts and needs no patched font.

If an icon renders but eats the gap after it, enable Footer → Other → Extra space after Nerd icons (`footerSegments.nerdIconSpacing`). In Kitty, `narrow_symbols U+E000-U+F8FF 1` in `kitty.conf` is an alternative.

Missing glyphs only affect rendering; the numbers in the footer stay correct.
