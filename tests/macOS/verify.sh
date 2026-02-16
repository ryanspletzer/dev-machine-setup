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

# Homebrew cask
check "iTerm2 installed (Homebrew cask)" test -d /Applications/iTerm.app

# pipx package
check "ruff installed (pipx package)" command -v ruff

# VS Code extension
check "redhat.vscode-yaml installed (VS Code extension)" \
  sh -c "code --list-extensions 2>/dev/null | grep -qi redhat.vscode-yaml"

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
