#!/bin/bash

# Remove unwanted feed sources
sed -i '/telephony/d' feeds.conf.default

# Add custom feed sources
echo 'src-git daed https://github.com/QiuSimons/luci-app-daed' >> feeds.conf.default
echo 'src-git wrtbwmon https://github.com/brvphoenix/wrtbwmon' >> feeds.conf.default
echo 'src-git wrtbwmon_luci https://github.com/brvphoenix/luci-app-wrtbwmon' >> feeds.conf.default
echo 'src-git sirpdboy https://github.com/sirpdboy/sirpdboy-package' >> feeds.conf.default

# Add ImmortalWrt 24.10 official feeds
echo 'src-git-full base https://github.com/immortalwrt/immortalwrt.git' >> feeds.conf.default
echo 'src-git packages https://github.com/immortalwrt/packages.git' >> feeds.conf.default
echo 'src-git luci https://github.com/immortalwrt/luci.git' >> feeds.conf.default
echo 'src-git routing https://github.com/openwrt/routing.git' >> feeds.conf.default
echo 'src-git telephony https://github.com/openwrt/telephony.git' >> feeds.conf.default
