# Install Guide

MultiWAN NFT can be installed from the combined router feed, built from an
OpenWrt SDK source feed, or copied with the raw installer for development and
recovery work.

The combined router feed is recommended for normal installs.

## Router Package Feed

Install all MultiWAN packages:

```sh
uclient-fetch -O /tmp/setup-multiwan-feed.sh https://raw.githubusercontent.com/mrep1c/openwrt-multiwan/main/setup-feed.sh
sh /tmp/setup-multiwan-feed.sh install
```

Install backend services only:

```sh
sh /tmp/setup-multiwan-feed.sh main
```

Install LuCI apps only:

```sh
sh /tmp/setup-multiwan-feed.sh luci
```

Manual OpenWrt 25.12 or newer install:

```sh
mkdir -p /etc/apk/keys /etc/apk/repositories.d
uclient-fetch -O /etc/apk/keys/mrep1c-openwrt-multiwan-apk.pem https://github.com/mrep1c/openwrt-multiwan/releases/download/apk-25.12-noarch/mrep1c-openwrt-multiwan-apk.pem
echo "https://github.com/mrep1c/openwrt-multiwan/releases/download/apk-25.12-noarch/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
apk update
apk add multiwan-nft luci-app-multiwan-nft
```

Manual OpenWrt 24.10 install:

```sh
uclient-fetch -O /tmp/mrep1c-openwrt-multiwan-opkg.pub https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-24.10-noarch/mrep1c-openwrt-multiwan-opkg.pub
opkg-key add /tmp/mrep1c-openwrt-multiwan-opkg.pub
echo "src/gz multiwan https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-24.10-noarch" >> /etc/opkg/customfeeds.conf
opkg update
opkg install multiwan-nft luci-app-multiwan-nft
```

Manual OpenWrt 23.05 install:

```sh
uclient-fetch -O /tmp/mrep1c-openwrt-multiwan-opkg.pub https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-23.05-noarch/mrep1c-openwrt-multiwan-opkg.pub
opkg-key add /tmp/mrep1c-openwrt-multiwan-opkg.pub
echo "src/gz multiwan https://github.com/mrep1c/openwrt-multiwan/releases/download/opkg-23.05-noarch" >> /etc/opkg/customfeeds.conf
opkg update
opkg install multiwan-nft luci-app-multiwan-nft
```

## SDK Source Feed

Use this source feed with the OpenWrt SDK/buildroot:

```sh
echo "src-git multiwan_nft https://github.com/mrep1c/openwrt-multiwan-nft.git" >> feeds.conf.default
./scripts/feeds update multiwan_nft
./scripts/feeds install -p multiwan_nft multiwan-nft luci-app-multiwan-nft
make menuconfig
```

Build packages:

```sh
make package/feeds/multiwan_nft/multiwan-nft/compile V=s
make package/feeds/multiwan_nft/luci-app-multiwan-nft/compile V=s
```

## Raw Installer

```sh
uclient-fetch -O /tmp/install-multiwan-nft.sh https://raw.githubusercontent.com/mrep1c/openwrt-multiwan-nft/main/install.sh
sh /tmp/install-multiwan-nft.sh
```

Backend only:

```sh
sh /tmp/install-multiwan-nft.sh main
```

Start service after backend install:

```sh
START_SERVICES=1 sh /tmp/install-multiwan-nft.sh main
```

## Verification

```sh
/etc/init.d/multiwan-nft status
nft list table inet mwan3
ip rule show
```

## Optional Firewall Mask Change

The default routing mark mask is `0x3F0000`. A custom mask must be
hexadecimal, contain at least three set bits, and avoid the lower byte
`0x000000ff` reserved for MultiWAN QoS.

Example:

```sh
uci set multiwan-nft.globals.mmx_mask='0x00FC0000'
uci commit multiwan-nft
/etc/init.d/multiwan-nft restart
/etc/init.d/multiwan-qos restart
```
