#!/bin/sh
# bump-cursor.sh
# Refreshes the pinned Cursor AppImage url and sha256 checksum across every
# vars.yaml that installs Cursor (ubuntu/debian/fedora and their examples).
#
# Cursor publishes only hash-versioned direct URLs and no official
# checksums, so the hash is computed from the download itself
# (trust-on-first-use): it cannot authenticate the initial download, but
# it pins the artifact so any later change at the same URL -- CDN
# tampering or corruption -- fails the Ansible get_url step loudly.
#
# Usage: scripts/bump-cursor.sh
# Run from anywhere; paths resolve relative to the repo root.

set -e

api_url='https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable'

repo_root=$(cd "$(dirname "$0")/.." && pwd)

set -- \
  "$repo_root/ubuntu/vars.yaml" \
  "$repo_root/debian/vars.yaml" \
  "$repo_root/fedora/vars.yaml" \
  "$repo_root/examples/ubuntu_vars.yaml" \
  "$repo_root/examples/debian_vars.yaml" \
  "$repo_root/examples/fedora_vars.yaml"

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required" >&2
  exit 1
fi

# Extract a top-level string field from the API's single-line JSON response
json_field() {
  sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p"
}

echo "Querying $api_url"
response=$(curl -fsSL "$api_url")
download_url=$(printf '%s' "$response" | json_field downloadUrl)
version=$(printf '%s' "$response" | json_field version)

if [ -z "$download_url" ] || [ -z "$version" ]; then
  echo "Error: could not parse downloadUrl/version from API response" >&2
  exit 1
fi

echo "Latest stable: $version"
echo "URL: $download_url"

current_url=$(sed -n 's|^ *url: "\(https://downloads\.cursor\.com[^"]*\)"$|\1|p' "$1")
if [ "$current_url" = "$download_url" ] && grep -q '^    checksum: "sha256:' "$1"; then
  echo "Already pinned to the latest stable with a checksum; nothing to do."
  exit 0
fi

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT INT TERM
echo "Downloading the AppImage once to compute its sha256..."
curl -fsSL -o "$tmp_file" "$download_url"

if command -v sha256sum >/dev/null 2>&1; then
  hash=$(sha256sum "$tmp_file" | awk '{print $1}')
else
  hash=$(shasum -a 256 "$tmp_file" | awk '{print $1}')
fi
echo "sha256: $hash"

for f in "$@"; do
  sed -i.bak \
    -e "s|url: \"https://downloads\.cursor\.com/[^\"]*\"|url: \"$download_url\"|" \
    "$f"
  if grep -q '^    checksum: "sha256:' "$f"; then
    # Refresh an existing pin
    sed -i.bak \
      -e "s|^    checksum: \"sha256:[0-9a-f]*\"|    checksum: \"sha256:$hash\"|" \
      "$f"
  else
    # First pin: turn the commented placeholder into a real checksum and
    # replace its lead-in comment
    sed -i.bak \
      -e 's|^    # Optional: set to a checksum value (e\.g\. "sha256:abc123\.\.\.") to verify the download$|    # sha256 of the pinned AppImage; refresh with url via scripts/bump-cursor.sh|' \
      -e "s|^    # checksum: \"sha256:abc123\.\.\.\"$|    checksum: \"sha256:$hash\"|" \
      "$f"
  fi
  rm -f "$f.bak"
  echo "Updated: $f"
done

echo "Done. Review the changes with: git diff"
