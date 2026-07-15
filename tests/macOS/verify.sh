#!/bin/sh
# verify.sh
# Post-integration verification for macOS setup
set -e

# shellcheck source=tests/lib/assert.sh
. "$(dirname "$0")/../lib/assert.sh"

# Homebrew formulae
check "jq installed (Homebrew formula)" command -v jq
check "git-lfs installed (Homebrew formula)" command -v git-lfs

# Homebrew tap
check "hashicorp/tap tapped (Homebrew tap)" sh -c 'brew tap | grep -q "^hashicorp/tap$"'

# Homebrew cask
check "iTerm2 installed (Homebrew cask)" test -d /Applications/iTerm.app
check "VS Code installed (Homebrew cask)" test -d "/Applications/Visual Studio Code.app"

# VS Code extension
check "gitignore extension installed (VS Code)" sh -c 'code --list-extensions | grep -qi "^codezombiech.gitignore$"'

# uv tool
check "ruff installed (uv tool)" command -v ruff

# pnpm + bun (Homebrew formulae)
check "pnpm installed (Homebrew formula)" command -v pnpm
check "bun installed (Homebrew formula)" command -v bun

# pnpm + bun global packages (distinct packages so each tool is verified independently)
check "json installed (pnpm global)" test -e "$HOME/Library/pnpm/bin/json"
check "cowsay installed (bun global)" test -e "$HOME/.bun/bin/cowsay"

# npm global package
check "semver installed (npm global)" command -v semver

# .NET global tool
check "dotnetsay installed (.NET global tool)" test -x "$HOME/.dotnet/tools/dotnetsay"

# Custom commands (sentinel files prove they ran)
check "user custom command ran" test -f "$HOME/.dms-ci-user-command-ran"
check "elevated custom command ran" test -f /etc/dms-ci-elevated-command-ran

# Git config
check_equal "git user.email configured" \
  "$(git config --global user.email)" "ci-test@example.com"
check_equal "git user.name configured" \
  "$(git config --global user.name)" "CI Test User"

finish
