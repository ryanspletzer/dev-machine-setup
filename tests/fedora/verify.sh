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
