#!/bin/sh
set -eu

repo_root="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

status=0
fail() { printf 'ERROR: %s\n' "$*" >&2; status=1; }

[ -f VERSION ] || { fail "missing VERSION file"; exit "$status"; }
version="$(tr -d ' \t\r\n' < VERSION)"
[ -n "$version" ] || fail "VERSION is empty"

check_line() {
	file="$1"
	pattern="$2"
	expected="$3"
	label="$4"
	count="$(grep -Ec "$pattern" "$file" || true)"
	if [ "$count" -ne 1 ]; then
		fail "expected exactly one $label in $file, found $count"
		return
	fi
	line="$(grep -E "$pattern" "$file" | tr -d '\r')"
	[ "$line" = "$expected" ] || fail "$label mismatch in $file: expected '$expected', found '$line'"
}

check_line "multiwan-nft/Makefile" '^PKG_VERSION:=' "PKG_VERSION:=$version" "multiwan-nft PKG_VERSION"
release="$(grep -E '^PKG_RELEASE:=' multiwan-nft/Makefile | tr -d '\r')"
release="${release#PKG_RELEASE:=}"
case "$release" in ''|*[!0-9]*) fail "multiwan-nft PKG_RELEASE must be numeric" ;; esac
check_line "luci-app-multiwan-nft/Makefile" '^PKG_VERSION:=' "PKG_VERSION:=$version" "luci-app-multiwan-nft PKG_VERSION"
check_line "luci-app-multiwan-nft/Makefile" '^PKG_RELEASE:=' "PKG_RELEASE:=$release" "luci-app-multiwan-nft PKG_RELEASE"
check_line "luci-app-multiwan-nft/Makefile" '^PKG_PO_VERSION:=' "PKG_PO_VERSION:=$version-r$release" "luci-app-multiwan-nft PKG_PO_VERSION"
grep -Fqx "## v$version" RELEASE_NOTES.md || fail "RELEASE_NOTES.md is missing the v$version heading"
grep -Fq 'Release notes pending.' RELEASE_NOTES.md && fail "RELEASE_NOTES.md still contains a pending release-note placeholder"

[ "$status" -eq 0 ] || exit "$status"
printf 'Version sync OK: %s\n' "$version"
