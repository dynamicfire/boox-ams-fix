#!/system/bin/sh
# Clear pre-compiled oat cache for services.jar
# This forces the system to use the DEX from our patched services.jar
MODDIR=${0%/*}
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.vdex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.vdex 2>/dev/null
