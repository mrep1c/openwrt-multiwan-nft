#!/bin/sh
set -eu

usage() {
	printf 'Usage: %s <version> [release] [notes-file]\n' "$0" >&2
	exit 2
}

die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

[ "$#" -ge 1 ] && [ "$#" -le 3 ] || usage

version="$1"
release="${2:-1}"
notes_file="${3:-}"

printf '%s\n' "$version" | grep -Eq '^[0-9]+([.][0-9]+){1,3}([+._-][A-Za-z0-9][A-Za-z0-9+._-]*)?$' ||
	die "invalid version: $version"
printf '%s\n' "$release" | grep -Eq '^[0-9]+$' ||
	die "invalid package release: $release"

notes_path=""
if [ -n "$notes_file" ]; then
	[ -r "$notes_file" ] || die "notes file is not readable: $notes_file"
	notes_dir="$(CDPATH= cd "$(dirname "$notes_file")" && pwd)"
	notes_path="${notes_dir}/$(basename "$notes_file")"
fi

repo_root="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

replace_unique_line() {
	file="$1"
	pattern="$2"
	replacement="$3"
	label="$4"

	[ -f "$file" ] || die "missing file for $label: $file"
	count="$(grep -Ec "$pattern" "$file" || true)"
	[ "$count" -eq 1 ] || die "expected exactly one $label in $file, found $count"

	tmp="$(mktemp "${TMPDIR:-/tmp}/multiwan-bump.XXXXXX")" ||
		die "could not create temp file"
	awk -v pat="$pattern" -v repl="$replacement" '
		$0 ~ pat { print repl; next }
		{ print }
	' "$file" > "$tmp" || {
		rm -f "$tmp"
		die "failed to update $file"
	}
	mv "$tmp" "$file"
}

ensure_release_notes() {
	file="RELEASE_NOTES.md"
	[ -f "$file" ] || die "missing release notes: $file"
	grep -Fqx "## v$version" "$file" && return 0

	tmp="$(mktemp "${TMPDIR:-/tmp}/multiwan-notes.XXXXXX")" ||
		die "could not create temp file"
	{
		sed -n '1p' "$file"
		printf '\n## v%s\n\n' "$version"
		if [ -n "$notes_path" ]; then
			cat "$notes_path"
			printf '\n'
		else
			printf 'Release notes pending.\n'
		fi
		printf '\n'
		sed '1d' "$file" | sed '1{/^$/d;}'
	} > "$tmp" || {
		rm -f "$tmp"
		die "failed to update $file"
	}
	mv "$tmp" "$file"
}

printf '%s\n' "$version" > VERSION
replace_unique_line "multiwan-nft/Makefile" '^PKG_VERSION:=' "PKG_VERSION:=$version" "multiwan-nft PKG_VERSION"
replace_unique_line "multiwan-nft/Makefile" '^PKG_RELEASE:=' "PKG_RELEASE:=$release" "multiwan-nft PKG_RELEASE"
replace_unique_line "luci-app-multiwan-nft/Makefile" '^PKG_VERSION:=' "PKG_VERSION:=$version" "luci-app-multiwan-nft PKG_VERSION"
replace_unique_line "luci-app-multiwan-nft/Makefile" '^PKG_RELEASE:=' "PKG_RELEASE:=$release" "luci-app-multiwan-nft PKG_RELEASE"
replace_unique_line "luci-app-multiwan-nft/Makefile" '^PKG_PO_VERSION:=' "PKG_PO_VERSION:=$version-r$release" "luci-app-multiwan-nft PKG_PO_VERSION"
ensure_release_notes
printf 'Updated MultiWAN NFT package versions to %s-r%s\n' "$version" "$release"
