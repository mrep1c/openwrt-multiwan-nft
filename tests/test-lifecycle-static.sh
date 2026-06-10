#!/bin/sh
set -eu

repo_root="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
status=0

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	status=1
}

check_lf() {
	file="$1"
	if LC_ALL=C grep -q "$(printf '\r')" "$file"; then
		fail "$file contains CRLF/carriage-return bytes"
	fi
}

rtmon="$repo_root/multiwan-nft/files/usr/sbin/multiwan-nft-rtmon"
nft_init="$repo_root/multiwan-nft/files/etc/init.d/multiwan-nft"

for file in \
	"$repo_root/multiwan-nft/files/etc/init.d/multiwan-nft" \
	"$repo_root/multiwan-nft/files/lib/multiwan-nft/common.sh" \
	"$repo_root/multiwan-nft/files/lib/multiwan-nft/process-lock.sh" \
	"$repo_root/multiwan-nft/files/usr/sbin/multiwan-nft-rtmon" \
	"$repo_root/multiwan-nft/files/usr/sbin/multiwan-nft-track"
do
	check_lf "$file"
done

grep -Eq 'monitor route[[:space:]]*\|[[:space:]]*while' "$rtmon" &&
	fail "route monitor still uses an anonymous pipeline reader"
grep -Fq 'exec 3<> "$RTMON_FIFO"' "$rtmon" ||
	fail "route monitor does not own an RDWR FIFO"
grep -Fq 'wait "$RTMON_PID"' "$rtmon" ||
	fail "route monitor child is not reaped"
grep -Fq 'mktemp -d "/tmp/multiwan-nft-rtmon-${family}.XXXXXX"' "$rtmon" ||
	fail "route monitor workspace is not unique and BusyBox-compatible"
grep -Fq 'mw_lock_read_owner "$RTMON_WORK_DIR"' "$rtmon" ||
	fail "route monitor cleanup does not verify workspace ownership"
grep -Fq 'multiwan-nft-rtmon-${family}-$$.fifo' "$rtmon" &&
	fail "route monitor still derives its FIFO path from a reusable PID"

stop_line="$(grep -n '^stop_service()' "$nft_init" | cut -d: -f1)"
stopped_line="$(grep -n '^service_stopped()' "$nft_init" | cut -d: -f1)"
init_line="$(awk -v start="$stopped_line" 'NR > start && /multiwan_nft_init/ { print NR; exit }' "$nft_init")"
[ -n "$stop_line" ] && [ -n "$stopped_line" ] && [ "$stopped_line" -gt "$stop_line" ] ||
	fail "NFT init does not use the rc.common service_stopped lifecycle hook"
[ -n "$init_line" ] && [ "$init_line" -gt "$stopped_line" ] ||
	fail "NFT fallback cleanup does not run after procd stops the service"
grep -A 8 '^stop_service()' "$nft_init" |
	grep -Eq '^[[:space:]]*(type .*&&[[:space:]]*)?procd_kill[[:space:]]' &&
	fail "NFT stop duplicates rc.common procd_kill"

[ "$status" -eq 0 ] || exit "$status"
printf 'Lifecycle static checks passed\n'
