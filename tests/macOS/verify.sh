#!/bin/sh
# verify.sh
# Post-integration verification for macOS setup
set -e

FAILURES=0

check() {
  description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    FAILURES=$((FAILURES + 1))
  fi
}

check_equal() {
  description="$1"
  actual="$2"
  expected="$3"
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description (expected '$expected', got '$actual')"
    FAILURES=$((FAILURES + 1))
  fi
}

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

# Git config
check_equal "git user.email configured" \
  "$(git config --global user.email)" "ci-test@example.com"
check_equal "git user.name configured" \
  "$(git config --global user.name)" "CI Test User"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES check(s) failed"
  exit 1
else
  echo "All checks passed"
fi
