# Release Notes

## v1.0.3

NFT process lifecycle hardening.

- Makes each route-monitor parent own, terminate, and reap its `ip monitor`
  child without an anonymous pipeline reader.
- Uses private owner-validated workspaces so stale route-monitor FIFOs cannot
  collide when the kernel reuses a forcibly killed parent's PID.
- Disables procd respawn before fallback cleanup and recovers only exact
  orphan route monitors adopted by PID 1.
- Hardens tracking probe, sleep, and package-lock ownership against PID reuse.
- Preserves existing policies, route handling, and address-family behavior.

## v1.0.2

NFT route monitor cleanup hotfix on top of v1.0.1.

- Cleans up orphaned `ip -4 monitor route` and `ip -6 monitor route`
  processes during MultiWAN NFT stop/restart.

## v1.0.1

Safe quality-of-life backport on top of v1.0.0.

- Keeps OpenWrt 23.05/24.10/25.12 package-feed compatibility through the
  combined feed.
- Adds version-sync tooling for future package-visible releases.
- Adds defensive nft transaction temp-file and error-output handling.
- Makes expensive diagnostics debug/failure-only.
- Starts route monitors only for enabled configured address families while
  leaving the original route-monitor loop intact.
- Improves LuCI mark-mask guidance and user-script save feedback.

## v1.0.0

MultiWAN NFT provides nftables-native multi-WAN routing for OpenWrt.

Included packages:

- `multiwan-nft`
- `luci-app-multiwan-nft`

Highlights:

- WAN health tracking.
- Failover and load-balancing policies.
- nftables routing mark handling.
- LuCI configuration and status pages.
- Source-feed support for SDK/buildroot users.
- Router package availability through the combined MultiWAN feed.

Notes:

- Official OpenWrt is the supported target.
- The public feed package is architecture-independent.
- The optional sockopt wrapper is available from source for SDK builds.
