#!/usr/bin/env bash
# Restore this repository's global config into a fresh environment.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
agent_dir=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
agents_dir=$HOME/.agents
stamp=$(date +%Y%m%d%H%M%S)
force=0

case ${1:-} in
	'') ;;
	--force) force=1 ;;
	*)
		echo "usage: $0 [--force]" >&2
		exit 2
		;;
esac

if ! command -v pi >/dev/null; then
	echo "pi is not on PATH; install it with: npm i -g @earendil-works/pi-coding-agent" >&2
	exit 1
fi

# Copies src to dst, backing up an existing dst when --force is given.
write_file() {
	local src=$1 dst=$2
	if [[ -e $dst && $force -eq 0 ]]; then
		echo "keep    $dst"
		return
	fi
	if [[ -e $dst ]]; then
		mv "$dst" "$dst.bak.$stamp"
		echo "backup  $dst.bak.$stamp"
	fi
	mkdir -p "$(dirname "$dst")"
	cp "$src" "$dst"
	echo "write   $dst"
}

# Points dst at src, backing up an existing dst when --force is given.
link_path() {
	local src=$1 dst=$2
	if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then
		echo "keep    $dst -> $src"
		return
	fi
	if [[ -e $dst && $force -eq 0 ]]; then
		echo "keep    $dst (not a symlink to $src; rerun with --force to replace)"
		return
	fi
	if [[ -e $dst || -L $dst ]]; then
		mv "$dst" "$dst.bak.$stamp"
		echo "backup  $dst.bak.$stamp"
	fi
	mkdir -p "$(dirname "$dst")"
	ln -s "$src" "$dst"
	echo "link    $dst -> $src"
}

write_file "$repo/pi/settings.json" "$agent_dir/settings.json"
write_file "$repo/pi/open-tui.json" "$agent_dir/open-tui.json"

# Both Pi and the Agent Skills layout read the instructions from their own directory.
link_path "$repo/AGENTS.md" "$agent_dir/AGENTS.md"
link_path "$repo/AGENTS.md" "$agents_dir/AGENTS.md"
link_path "$repo/.agents/agents" "$agents_dir/agents"

for skill in "$repo"/.agents/skills/*/; do
	link_path "$skill" "$agents_dir/skills/$(basename "$skill")"
done

# pi subagents read their own agent directory, not ~/.agents/agents.
for agent in "$repo"/pi/agents/*.md; do
	[[ -e $agent ]] || continue
	link_path "$agent" "$agent_dir/agents/$(basename "$agent")"
done

# Installs the packages declared in settings.json, which a fresh agent directory has none of.
pi update --extensions

font_dirs=("$HOME/Library/Fonts" "/Library/Fonts" "$HOME/.local/share/fonts")
if ! ls "${font_dirs[@]}" 2>/dev/null | grep -qi nerd; then
	echo
	echo "warning: no Nerd Font detected."
	echo "  pi-open-tui uses Nerd Font glyphs when icons.mode is \"auto\", so they render as boxed '?' marks."
	echo "  Fix it with: brew install --cask font-jetbrains-mono-nerd-font"
	echo "  then select that font in the terminal profile, or set icons.mode to \"unicode\" in $agent_dir/open-tui.json."
fi

echo
echo "done. Next: pi auth login deepseek (and any other provider you use)."
