#!/bin/sh
# verify.sh
# Post-integration verification for Fedora setup
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

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES check(s) failed"
  exit 1
else
  echo "All checks passed"
fi
