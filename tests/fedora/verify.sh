#!/bin/sh
# verify.sh
# Post-integration verification for Fedora setup
set -e

# shellcheck source=tests/lib/assert.sh
. "$(dirname "$0")/../lib/assert.sh"

# DNF prereqs
check "ca-certificates installed (DNF prereq)" rpm -q ca-certificates
check "curl installed (DNF prereq)" command -v curl

# DNF packages
check "git installed (DNF package)" command -v git
check "git-lfs installed (DNF package)" command -v git-lfs
check "jq installed (DNF package)" command -v jq
check "gh installed (external DNF repo)" command -v gh

# pnpm + bun (installed via npm into ~/.local/bin)
check "bun installed (npm global)" test -x "$HOME/.local/bin/bun"
check "pnpm installed (npm global)" test -x "$HOME/.local/bin/pnpm"

# pipx
check "uv installed (pipx)" sh -c 'pipx list --short | grep -q "^uv "'

# uv tool
check "ruff installed (uv tool)" test -x "$HOME/.local/bin/ruff"

# pnpm + bun global packages (distinct packages so each tool is verified independently)
check "json installed (pnpm global)" test -e "$HOME/.local/share/pnpm/bin/json"
check "cowsay installed (bun global)" test -e "$HOME/.bun/bin/cowsay"

# AppImage
check "appimagetool AppImage downloaded" test -x "$HOME/.local/bin/appimagetool.AppImage"
check "appimagetool CLI symlink created" test -L "$HOME/.local/bin/appimagetool"
check "appimagetool desktop entry created" test -f "$HOME/.local/share/applications/appimagetool.desktop"

# Custom commands (sentinel files prove they ran)
check "user custom command ran" test -f "$HOME/.dms-ci-user-command-ran"
check "elevated custom command ran" test -f /etc/dms-ci-elevated-command-ran

# Git config
check_equal "git user.email configured" \
  "$(git config --global user.email)" "ci-test@example.com"
check_equal "git user.name configured" \
  "$(git config --global user.name)" "CI Test User"

finish
