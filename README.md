# Boox AMS NullPointerException Fix

> 修复文石固件 4.1.x 上 Magisk App 启动崩溃的问题
>
> Fix Magisk app crash on Boox firmware 4.1.x

[![Firmware](https://img.shields.io/badge/Firmware-4.1.x-orange)]()
[![Magisk](https://img.shields.io/badge/Magisk_Module-v30.6-brightgreen)]()
[![SoC](https://img.shields.io/badge/SoC-SM7225-red)]()

**[中文](#中文) | [English](#english)**

---

# 中文

## 问题

文石固件 4.1.x 上，Magisk App 卡在启动画面无法进入主界面。Root 本身正常工作（`su -c id` 返回 uid=0），只有管理界面不可用。

已知受影响设备：

- Boox P6 Pro 小彩马 — 已验证修复
- Boox Note Air 3C — [Magisk #9319](https://github.com/topjohnwu/Magisk/issues/9319)
- Boox Palma 2 — [BooxPalma2RootGuide #8](https://github.com/jdkruzr/BooxPalma2RootGuide/issues/8)
- 其他使用 SM7225 (Snapdragon 750G) 且固件为 4.1 的文石设备

## 安装

从 [Releases](https://github.com/dynamicfire/boox-ams-fix/releases/) 下载 `boox-ams-fix-v1.0.zip`。

因为 Magisk App 无法打开，需要通过命令行安装：

```bash
adb push boox-ams-fix-v1.0.zip /sdcard/
adb shell su -c 'magisk --install-module /sdcard/boox-ams-fix-v1.0.zip'
adb reboot
```

重启后 Magisk App 即可正常启动。

## 卸载

```bash
adb shell su -c 'rm -rf /data/adb/modules/boox-ams-fix'
adb reboot
```

## 原因分析

文石在 `services.jar` 的 `ActivityManagerService.addPackageDependency()` 末尾添加了 WebView 使用追踪代码（`UpdateWebViewUsedPkgsAction`），用于墨水屏刷新优化。该代码无条件访问 `ProcessRecord.info.packageName`，但 Magisk 的 root 守护进程（uid 0）不在系统的 PidMap 中，`ProcessRecord` 为 null，触发 `NullPointerException`。

崩溃日志：

```
ActivityManager Crash. UID:0 PID:xxxx
java.lang.NullPointerException:
  Attempt to read from field 'android.content.pm.ApplicationInfo
    com.android.server.am.ProcessRecord.info'
  at com.android.server.am.ActivityManagerService
    .addPackageDependency(ActivityManagerService.java:4249)
```

崩溃链：

```
Magisk App 启动
  → RootServerMain.main() (uid 0)
    → LoadedApk.getClassLoader()
      → addPackageDependency()
        → PidMap.get(callingPid) → null
          → 文石代码访问 null.info → NPE
```

## 修复方式

对 `classes.dex` 做单字节修改，将 `ProcessRecord` 为 null 时的跳转目标从文石 WebView 代码改为 `return-void`：

```
偏移:    0x002b2f14
修补前:  38 01 33 00    (if-eqz v1, +0x33 → 文石 WebView 代码 → NPE)
修补后:  38 01 3F 00    (if-eqz v1, +0x3F → return-void)
```

| 场景 | 修补前 | 修补后 |
|---|---|---|
| 普通应用 (ProcessRecord ≠ null) | 正常运行 ✅ | **无变化** ✅ |
| Root 进程 (ProcessRecord = null) | NPE 崩溃 💥 | 安全返回 ✅ |

修补后重新计算了 DEX 的 SHA-1 签名和 Adler32 校验和。

## 模块信息

```
id=boox-ams-fix
name=Boox AMS NullPointerException Fix
version=v1.0
author=玄昼
```

模块通过 Magisk systemless overlay 替换 `/system/framework/services.jar`，不修改实际系统分区，可安全卸载。

## 注意事项

- 本模块专门针对固件 4.1 的 `services.jar`，其他固件版本不适用
- 如果文石后续更新固件修复了此问题，应卸载本模块
- OTA 更新后可能需要重新安装

## 相关项目

- [boox-p6pro-root](https://github.com/dynamicfire/boox-p6pro-root) — P6 Pro 小彩马完整 Root 指南（包含 EDL 解锁 Bootloader）

## 致谢

- **[topjohnwu/Magisk](https://github.com/topjohnwu/Magisk)** — Root 方案
- **[Kisuke](https://github.com/Kisuke-CZE/Palma_2_Pro-tips#rooting-palma-2-pro)** — Palma 2 Pro Root 方法

---
---

# English

## Problem

On Boox firmware 4.1.x, the Magisk app freezes on the splash screen and never reaches the main UI. Root itself works fine (`su -c id` returns uid=0) — only the management interface is broken.

Known affected devices:

- Boox P6 Pro 小彩马 — fix verified
- Boox Note Air 3C — [Magisk #9319](https://github.com/topjohnwu/Magisk/issues/9319)
- Boox Palma 2 — [BooxPalma2RootGuide #8](https://github.com/jdkruzr/BooxPalma2RootGuide/issues/8)
- Other Boox devices with SM7225 (Snapdragon 750G) SoC on firmware 4.1

## Install

Download `boox-ams-fix-v1.0.zip` from the [Releases](https://github.com/dynamicfire/boox-ams-fix/releases/) page.

Since the Magisk app can't open, install via command line:

```bash
adb push boox-ams-fix-v1.0.zip /sdcard/
adb shell su -c 'magisk --install-module /sdcard/boox-ams-fix-v1.0.zip'
adb reboot
```

The Magisk app should launch normally after reboot.

## Uninstall

```bash
adb shell su -c 'rm -rf /data/adb/modules/boox-ams-fix'
adb reboot
```

## Root Cause

Boox added WebView usage tracking code (`UpdateWebViewUsedPkgsAction`) at the end of `ActivityManagerService.addPackageDependency()` in `services.jar`, likely for e-ink refresh optimization. This code unconditionally accesses `ProcessRecord.info.packageName`, but Magisk's root daemon (uid 0) is not in the system's PidMap, so `ProcessRecord` is null, triggering a `NullPointerException`.

Crash log:

```
ActivityManager Crash. UID:0 PID:xxxx
java.lang.NullPointerException:
  Attempt to read from field 'android.content.pm.ApplicationInfo
    com.android.server.am.ProcessRecord.info'
  at com.android.server.am.ActivityManagerService
    .addPackageDependency(ActivityManagerService.java:4249)
```

Crash chain:

```
Magisk App launch
  → RootServerMain.main() (uid 0)
    → LoadedApk.getClassLoader()
      → addPackageDependency()
        → PidMap.get(callingPid) → null
          → Boox code accesses null.info → NPE
```

## The Fix

A single-byte change in `classes.dex` redirects the null-branch jump from the Boox WebView code to `return-void`:

```
Offset:  0x002b2f14
Before:  38 01 33 00    (if-eqz v1, +0x33 → Boox WebView code → NPE)
After:   38 01 3F 00    (if-eqz v1, +0x3F → return-void)
```

| Scenario | Before Patch | After Patch |
|---|---|---|
| Normal apps (ProcessRecord ≠ null) | Works normally ✅ | **No change** ✅ |
| Root process (ProcessRecord = null) | NPE crash | Safe return ✅ |

DEX SHA-1 signature and Adler32 checksum were recalculated after patching.

## Module Info

```
id=boox-ams-fix
name=Boox AMS NullPointerException Fix
version=v1.0
author=玄昼
```

The module uses Magisk's systemless overlay to replace `/system/framework/services.jar` without touching the actual system partition. Safe to uninstall at any time.

## Notes

- This module targets `services.jar` from firmware 4.1 specifically; other firmware versions are not supported
- If Boox fixes this in a future firmware update, uninstall this module
- May need to be reinstalled after OTA updates

## Related

- [boox-p6pro-root](https://github.com/dynamicfire/boox-p6pro-root) — Full root guide for P6 Pro 小彩马 (includes EDL bootloader unlock)

## Credits

- **[topjohnwu/Magisk](https://github.com/topjohnwu/Magisk)** — Root solution
- **[Kisuke](https://github.com/Kisuke-CZE/Palma_2_Pro-tips#rooting-palma-2-pro)** — Palma 2 Pro root method
