#!/bin/bash

# Remove unwanted feed sources
sed -i '/telephony/d' feeds.conf.default

# Add custom feed sources
echo 'src-git daed https://github.com/QiuSimons/luci-app-daed' >> feeds.conf.default
echo 'src-git wrtbwmon https://github.com/brvphoenix/wrtbwmon' >> feeds.conf.default
echo 'src-git wrtbwmon_luci https://github.com/brvphoenix/luci-app-wrtbwmon' >> feeds.conf.default
echo 'src-git sirpdboy https://github.com/sirpdboy/sirpdboy-package' >> feeds.conf.default
# Add xiaorouji's Passwall2 repo
echo "src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2" >> feeds.conf.default

 
