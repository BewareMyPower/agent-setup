# Global agent config

My personal global setup for coding agents, reused on every machine: shared instructions, skills, and Pi configuration.

| Path               | Contents                                                          |
| ------------------ | ----------------------------------------------------------------- |
| `AGENTS.md`        | Global instructions applied to every session.                     |
| `.agents/skills/`  | Global skills.                                                    |
| `.agents/agents/`  | Subagent definitions used by the skills.                          |
| `pi/settings.json` | Pi user settings: theme, default model, thinking level, packages. |
| `pi/open-tui.json` | Footer and interface options for the `pi-open-tui` extension.     |
| `pi/setup.sh`      | Bootstrap for a fresh machine.                                    |

## Fresh machine

Prerequisites: Node.js with `pi` installed (`npm i -g @earendil-works/pi-coding-agent`), and a terminal font that can draw the footer icons (see [Terminal icons](#terminal-icons)).

```sh
git clone git@github.com:bewaremypower/development-skills.git
cd development-skills
./pi/setup.sh
pi auth login deepseek
```

Repeat `pi auth login <provider>` for every provider you use; credentials are never stored in this repository.

`setup.sh` writes `pi/settings.json` and `pi/open-tui.json` into the agent directory (`$PI_CODING_AGENT_DIR`, default `~/.pi/agent`) only when those files are missing, symlinks `AGENTS.md` as both `~/.pi/agent/AGENTS.md` and `~/.agents/AGENTS.md`, links `.agents/skills/*` and `.agents/agents` into `~/.agents`, and finishes with `pi update --extensions` to install the packages declared in `settings.json`. Pass `--force` to replace existing files; their previous contents are kept as `<file>.bak.<timestamp>`.

Instructions and skills stay authoritative here: edit them in this repository and every machine picks the change up through the symlink. The two `pi/*.json` files are copies, so after changing a setting through `/settings` or `/open-tui` on any machine, copy that file back here and commit it.

Not committed on purpose: `auth.json` (API keys and OAuth tokens), `trust.json` and `trust/` (per-machine trust decisions keyed by absolute path), `sessions/`, `models-store.json` (regenerated model catalog cache), and the `npm/` and `git/` package installs.

## Terminal icons

Symptom: the footer shows boxed `?` marks where icons should be, next to the branch, runtime, context bar, token counts, cache rate, and cost.

Those marks are Nerd Font glyphs from the Unicode private use area, and the terminal font has no glyph for them. With `icons.mode: "auto"`, `pi-open-tui` picks ASCII only when stdout is not a TTY, `TERM=dumb`, or the first configured locale (`LC_ALL`, `LC_CTYPE`, `LANG`) is not UTF-8, and Unicode only when `SSH_TTY` or `SSH_CONNECTION` is set. Everywhere else it selects Nerd Font glyphs without inspecting the installed fonts, so a local session with Monaco, Menlo, or SF Mono renders a notdef box for each one. The same missing glyph is why those characters get stripped when the footer is copied into a chat message.

Fix it by either installing a patched font and selecting it in the terminal profile:

```sh
brew install --cask font-jetbrains-mono-nerd-font
# iTerm2: Settings → Profiles → Text → Font → JetBrainsMono Nerd Font
printf '\ue0a0 \ue5ff \uf015 \U000f0179\n'
```

or by dropping the glyphs entirely: set `"icons": { "mode": "unicode" }` in `~/.pi/agent/open-tui.json` (`ascii` for plain text), or cycle the value under Appearance → Icons in the `/open-tui` dialog. Unicode mode falls back to the terminal's emoji and symbol fonts and needs no patched font.

If an icon renders but eats the gap after it, enable Footer → Other → Extra space after Nerd icons (`footerSegments.nerdIconSpacing`). In Kitty, `narrow_symbols U+E000-U+F8FF 1` in `kitty.conf` is an alternative.

Missing glyphs only affect rendering; the numbers in the footer stay correct.
