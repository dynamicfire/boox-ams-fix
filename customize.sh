#!/system/bin/sh
ui_print "=========================================="
ui_print "  Boox AMS NullPointerException Fix v1.0"
ui_print "=========================================="
ui_print ""
ui_print "  Fixes Magisk app stuck at splash screen"
ui_print "  on Boox firmware 4.1+"
ui_print ""
ui_print "  Patch: addPackageDependency() null check"
ui_print "  Only 1 byte changed in services.jar"
ui_print ""
ui_print "  Clearing dalvik cache..."

# Clear dalvik cache for services.jar
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.vdex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.vdex 2>/dev/null

ui_print "  Done! Reboot to apply."
ui_print "=========================================="
