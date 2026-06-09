# OpenWrt MultiWAN NFT

MultiWAN NFT is an nftables-native multi-WAN manager for OpenWrt. It monitors
WAN interfaces, applies routing policies, and supports failover or
load-balancing rules without relying on iptables or ipset.

This repository contains two OpenWrt packages:

- `multiwan-nft`: backend service, init script, tracking scripts, nftables
  rules, routing logic, and UCI config.
- `luci-app-multiwan-nft`: optional LuCI application for configuration and
  status pages.

For normal router installs, use the combined feed at
`https://github.com/mrep1c/openwrt-multiwan`. One feed exposes MultiWAN NFT,
MultiWAN QoS, and both LuCI apps.

## Features

- nftables-native routing mark handling.
- WAN health tracking with configurable tracking IPs.
- Failover and load-balancing policies.
- LuCI pages for interfaces, members, policies, rules, diagnostics, and status.
- Routing mark layout designed to coexist with MultiWAN QoS DSCP marks.
- Native interface binding fallback when the optional sockopt wrapper is not
  installed.

If you customize `multiwan-nft.globals.mmx_mask`, keep the lower byte
(`0x000000ff`) clear so MultiWAN QoS can preserve DSCP state in conntrack
marks.

## Requirements

- OpenWrt with Firewall 4 and nftables.
- OpenWrt 25.12 or newer with `apk`, or OpenWrt 24.10/23.05 with `opkg`.
- Working OpenWrt package feeds for dependencies.
- WAN interfaces defined in `/etc/config/network`.

## Quick Install

Use the combined feed helper:

```sh
uclient-fetch -O /tmp/setup-multiwan-feed.sh https://raw.githubusercontent.com/mrep1c/openwrt-multiwan/main/setup-feed.sh
sh /tmp/setup-multiwan-feed.sh install
```

Backend only:

```sh
sh /tmp/setup-multiwan-feed.sh main
```

LuCI only, after the backend is installed:

```sh
sh /tmp/setup-multiwan-feed.sh luci
```

## Manual Router Install

OpenWrt 25.12 or newer:

```sh
mkdir -p /etc/apk/keys /etc/apk/repositories.d
uclient-fetch -O /etc/apk/keys/mrep1c-openwrt-multiwan-apk.pem https://github.com/mrep1c/openwrt-multiwan/releases/download/apk-25.12-noarch/mrep1c-openwrt-multiwan-apk.pem
echo "https://github.com/mrep1c/openwrt-multiwan/releases/download/apk-25.12-noarch/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
apk update
apk add multiwan-nft luci-app-multiwan-nft
```

OpenWrt 24.10:

```sh
uclient-fetch -O /tmp/mrep1c-openwrt-multiwan-opkg.pub https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-24.10-noarch/mrep1c-openwrt-multiwan-opkg.pub
opkg-key add /tmp/mrep1c-openwrt-multiwan-opkg.pub
echo "src/gz multiwan https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-24.10-noarch" >> /etc/opkg/customfeeds.conf
opkg update
opkg install multiwan-nft luci-app-multiwan-nft
```

OpenWrt 23.05:

```sh
uclient-fetch -O /tmp/mrep1c-openwrt-multiwan-opkg.pub https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-23.05-noarch/mrep1c-openwrt-multiwan-opkg.pub
opkg-key add /tmp/mrep1c-openwrt-multiwan-opkg.pub
echo "src/gz multiwan https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-23.05-noarch" >> /etc/opkg/customfeeds.conf
opkg update
opkg install multiwan-nft luci-app-multiwan-nft
```

## SDK Source Feed

Use this repository directly in the OpenWrt SDK/buildroot:

```sh
echo "src-git multiwan_nft https://github.com/mrep1c/openwrt-multiwan-nft.git" >> feeds.conf.default
./scripts/feeds update multiwan_nft
./scripts/feeds install -p multiwan_nft multiwan-nft luci-app-multiwan-nft
make menuconfig
```

The combined source feed is also available:

```sh
echo "src-git multiwan https://github.com/mrep1c/openwrt-multiwan.git" >> feeds.conf.default
```

## Raw Installer

The package feed is the recommended install path. The raw installer is useful
for development and recovery:

```sh
uclient-fetch -O /tmp/install-multiwan-nft.sh https://raw.githubusercontent.com/mrep1c/openwrt-multiwan-nft/main/install.sh
sh /tmp/install-multiwan-nft.sh
```

Backend only:

```sh
sh /tmp/install-multiwan-nft.sh main
```

Start the backend after install:

```sh
START_SERVICES=1 sh /tmp/install-multiwan-nft.sh main
```

## First Configuration

1. Configure WAN interfaces in `/etc/config/network`.
2. Open LuCI > Network > MultiWAN NFT.
3. Enable each WAN interface and add tracking IPs.
4. Create members and policies.
5. Create rules that select the desired policy.
6. Restart the service:

```sh
/etc/init.d/multiwan-nft restart
```

## Useful Paths

- `/etc/config/multiwan-nft`
- `/etc/init.d/multiwan-nft`
- `/etc/multiwan-nft.user`
- `/usr/sbin/multiwan-nft`
- `/usr/sbin/multiwan-nft-track`

## Verification

```sh
/etc/init.d/multiwan-nft status
nft list table inet mwan3
ip rule show
ip route show table all
```

## Troubleshooting

If LuCI pages do not appear:

```sh
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
```

If the service does not create nftables rules, confirm the configured WAN
interface names match `/etc/config/network`, then restart the service and check
the status output.

## Uninstall

```sh
apk del luci-app-multiwan-nft multiwan-nft
```

On OPKG systems:

```sh
opkg remove luci-app-multiwan-nft multiwan-nft
```

## Binary Notes

The public feed packages are architecture-independent and do not ship the
optional sockopt wrapper library. SDK users can build target-specific packages
from source when that wrapper is needed.
