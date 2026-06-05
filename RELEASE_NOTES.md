# Release Notes

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
