#!/usr/bin/env bats
# Argument-handling tests for the four setup.sh entry points.
#
# Only code paths that exit before any system change are exercised:
# getopts validation (which runs before logging, sudo, or package
# installs), plus the pure json_escape helper extracted with sed so it
# can be tested without executing the rest of the script.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

extract_json_escape() {
  sed -n '/^json_escape()/,/^}/p' "$REPO_ROOT/$1/setup.sh"
}

@test "macOS setup.sh rejects an invalid option" {
  run bash "$REPO_ROOT/macOS/setup.sh" -x
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid option"* ]]
}

@test "ubuntu setup.sh rejects an invalid option" {
  run bash "$REPO_ROOT/ubuntu/setup.sh" -x
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid option"* ]]
}

@test "debian setup.sh rejects an invalid option" {
  run bash "$REPO_ROOT/debian/setup.sh" -x
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid option"* ]]
}

@test "fedora setup.sh rejects an invalid option" {
  run bash "$REPO_ROOT/fedora/setup.sh" -x
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid option"* ]]
}

@test "every setup.sh fails when -e is missing its argument" {
  for platform in macOS ubuntu debian fedora; do
    run bash "$REPO_ROOT/$platform/setup.sh" -e
    [ "$status" -eq 1 ]
  done
}

@test "json_escape is defined identically on every platform" {
  extract_json_escape macOS > "$BATS_TEST_TMPDIR/macOS.sh"
  [ -s "$BATS_TEST_TMPDIR/macOS.sh" ]
  for platform in ubuntu debian fedora; do
    extract_json_escape "$platform" > "$BATS_TEST_TMPDIR/$platform.sh"
    diff "$BATS_TEST_TMPDIR/macOS.sh" "$BATS_TEST_TMPDIR/$platform.sh"
  done
}

@test "json_escape passes plain strings through unchanged" {
  source <(extract_json_escape ubuntu)
  [ "$(json_escape 'plain string')" = 'plain string' ]
  [ "$(json_escape "O'Brien")" = "O'Brien" ]
}

@test "json_escape escapes double quotes" {
  source <(extract_json_escape ubuntu)
  [ "$(json_escape 'CI "Test" User')" = 'CI \"Test\" User' ]
}

@test "json_escape escapes backslashes" {
  source <(extract_json_escape ubuntu)
  [ "$(json_escape 'a\b')" = 'a\\b' ]
}

@test "json_escape escapes backslashes before quotes (no double escaping)" {
  source <(extract_json_escape ubuntu)
  [ "$(json_escape '\"')" = '\\\"' ]
}
