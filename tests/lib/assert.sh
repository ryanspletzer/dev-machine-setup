#!/bin/sh
# assert.sh
# Shared helpers for the post-integration verify scripts.
# Source this, run check/check_equal assertions, then call finish.

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

finish() {
  echo ""
  if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES check(s) failed"
    exit 1
  else
    echo "All checks passed"
  fi
}
