# ByteFlow — UI & UX Design Specification

This document details the visual design language, Material 3 design tokens, screen-by-screen layouts, component wireframes, micro-interactions, and user experience flows for **ByteFlow**.

---

## 1. Design Language & Design System

### 1.1 Material 3 Principles & Responsive Constraints
- **Container Hierarchy**: Clean surface separation using Material 3 container tokens (`surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`).
- **Dynamic Color (Monet)**: Integrates `dynamic_color` so accent colors seamlessly harmonize with the user's Android 12+ wallpaper palette.
- **Dark Mode First**: Optimized with deep OLED surfaces (`#121316`) and vibrant high-contrast data indicators (`primary`, `tertiaryContainer`, `error`).
- **Adaptive Layout Rules (`flutter-build-responsive-layout`)**:
  - Always use `MediaQuery.sizeOf(context)` instead of `MediaQuery.of(context)` to prevent unnecessary rebuilds when unrelated window properties change.
  - Wrap top-level containers in `LayoutBuilder` evaluating `constraints.maxWidth`.
  - Breakpoint: `largeScreenMinWidth = 600.0`. Tablets and foldables switch from bottom `NavigationBar` to leading `NavigationRail`.
  - Prevent horizontal over-stretching: Wrap content columns in `ConstrainedBox(constraints: BoxConstraints(maxWidth: 800.0))`.
- **Layout Safety Rules (`flutter-fix-layout-issues`)**:
  - Zero unbounded height inside scrollables: lists nested inside columns use `shrinkWrap: true` or `SliverList` / `CustomScrollView`.
  - Virtualized lists (`ListView.builder`) specify fixed `itemExtent: 76.0` to eliminate dynamic height recalculation jank during 120 FPS fling scrolling.
- **Typography Scale**:
  - `DisplaySmall` / `HeadlineMedium`: Large numeric data readings (e.g., **"3.42 GB"**).
  - `TitleMedium` / `TitleLarge`: Section headers, card titles, carrier names.
  - `BodyMedium` / `BodySmall`: App package IDs, explanatory captions, timestamps.
  - `LabelSmall` / `LabelMedium`: Tags, badges (e.g., `JIO 5G`, `CELLULAR ACTIVE`, `BACKGROUND`).

---

## 2. Screen-by-Screen Layout & Wireframes

### Screen 1: Dashboard (Live Pulse & Daily Overview)

```
+-------------------------------------------------------------+
|  ByteFlow                 [📶 Jio 5G • SIM 1]        (⚙)   |
+-------------------------------------------------------------+
|                                                             |
|  +-------------------------------------------------------+  |
|  |  LIVE NETWORK SPEED                    [ ● Live Pulse]|  |
|  |                                                       |  |
|  |       ↓ 2.45 MB/s               ↑ 180.2 KB/s          |  |
|  |       Download                  Upload                |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  +-------------------------------------------------------+  |
|  |  MONTHLY DATA PLAN                                    |  |
|  |                                                       |  |
|  |              . - ~ ~ ~ - .                            |  |
|  |          . '     68%       ' .      3.40 GB Used      |  |
|  |        /      CONSUMED         \    1.60 GB Remaining |  |
|  |       |                         |   5.00 GB Total     |  |
|  |        \                       /                      |  |
|  |          . '                 ' .    [On Track 🟢]     |  |
|  |              ' - . _ . - '          12 Days Left      |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  +---------------------------+ +-------------------------+  |
|  |  MOBILE DATA TODAY        | |  WI-FI DATA TODAY       |  |
|  |  428.5 MB                 | |  1.82 GB                |  |
|  |  ↓ 385 MB  •  ↑ 43.5 MB   | |  ↓ 1.6 GB  •  ↑ 220 MB  |  |
|  +---------------------------+ +-------------------------+  |
|                                                             |
|  +-------------------------------------------------------+  |
|  |  TOP APPS TODAY                             View All >|  |
|  |  [YT] YouTube        210 MB   [████████████░░░░]  49% |  |
|  |  [CH] Chrome          85 MB   [█████░░░░░░░░░░░]  20% |  |
|  |  [IG] Instagram       64 MB   [████░░░░░░░░░░░░]  15% |  |
|  +-------------------------------------------------------+  |
|                                                             |
+-------------------------------------------------------------+
|  [⚡ Dashboard]    [📱 Apps]    [📈 History]    [📋 Plan]   |
+-------------------------------------------------------------+
```

---

### Screen 2: App Breakdown (Data Detective)

```
+-------------------------------------------------------------+
|  App Data Usage                                      (🔍)   |
+-------------------------------------------------------------+
|  [ Search application...                                  ] |
|                                                             |
|  Network:  (● All)    (○ Mobile Only)    (○ Wi-Fi Only)     |
|  Range:    [ Today ]    [ Weekly ]    [ Monthly ]   [ Yearly]|
+-------------------------------------------------------------+
|  Total Usage: 2.25 GB across 42 active apps                 |
|                                                             |
|  +-------------------------------------------------------+  |
|  |  [YouTube Icon]   YouTube                   1.12 GB   |  |
|  |  com.google.android.youtube                 50%       |  |
|  |  [████████████████████████████████░░░░░░░░░░░░░░░░░]  |  |
|  |  🟢 Foreground: 1.05 GB   •   🔵 Background: 70 MB    |  |
|  +-------------------------------------------------------+  |
|  |  [Instagram Icon] Instagram                 480 MB    |  |
|  |  com.instagram.android                      21%       |  |
|  |  [█████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]  |  |
|  |  🟢 Foreground: 320 MB    •   ⚠️ Background: 160 MB   |  |
|  +-------------------------------------------------------+  |
|  |  [Chrome Icon]    Google Chrome             240 MB    |  |
|  |  com.android.chrome                         11%       |  |
|  |  [███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]  |  |
|  |  🟢 Foreground: 210 MB    •   🔵 Background: 30 MB    |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  Tap any app to view detailed usage timeline & system info  |
+-------------------------------------------------------------+
|  [⚡ Dashboard]    [📱 Apps]    [📈 History]    [📋 Plan]   |
+-------------------------------------------------------------+
```

---

### Screen 3: History & Trends (Multi-Timeframe Analytics)

```
+-------------------------------------------------------------+
|  Usage History & Spikes                                     |
+-------------------------------------------------------------+
|  Range: [ Today ]    [ Weekly ]    [ Monthly ]    [ Yearly ]|
+-------------------------------------------------------------+
|                                                             |
|  [ TODAY MODE: 24-HOUR ACTIVITY ]                           |
|  MB                                                         |
|  120|               ▲ Peak: 14:00 (115 MB)                  |
|   90|               █                                       |
|   60|        █      █                                       |
|   30|   █    █      █   █          █   █                    |
|    0+---+----+------+---+----------+---+------------------  |
|     00  04   08     12  14         18  22   Hour            |
|                                                             |
|  [ WEEKLY MODE: 7-DAY COMPARATIVE BARS ]                    |
|  GB  ■ Mobile  □ Wi-Fi                                      |
|  3.0|              ■□                                       |
|  2.0|      ■□      ■□      ■□                               |
|  1.0|  ■□  ■□  ■□  ■□  ■□  ■□  ■□                           |
|    0+---+---+---+---+---+---+---+-------------------------  |
|      Mon Tue Wed Thu Fri Sat Sun                            |
|                                                             |
|  [ MONTHLY MODE: 30-DAY CUMULATIVE BURN LINE ]              |
|  GB  ── Actual Used   -- - Ideal Quota Pace                 |
|  5.0|                                         / (Quota Limit|
|  3.0|                           . - - ' ' '                 |
|  1.0|                 . - ' '                               |
|    0+---+---+---+---+---+---+---+-------------------------  |
|      Day 1    Day 7    Day 14    Day 21   Day 28            |
|                                                             |
|  [ YEARLY MODE: 12-MONTH HISTORICAL DISTRIBUTION ]          |
|  GB                                                         |
|   80|      █       █   █                                    |
|   40|  █   █   █   █   █   █   █   █   █   █   █   █        |
|    0+---+---+---+---+---+---+---+---+---+---+---+---+-----  |
|      Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec        |
|                                                             |
|                                                             |
|  +-------------------------------------------------------+  |
|  |  SPIKE ANALYSIS                                       |  |
|  |  • Peak activity occurred at 2:00 PM - 3:00 PM        |  |
|  |  • Primary consumer during peak: YouTube (85 MB)      |  |
|  |  • Unusual background spike detected at 3:00 AM (40MB)|  |
|  +-------------------------------------------------------+  |
|                                                             |
|  DAILY METRICS SUMMARY                                      |
|  +---------------------------+ +-------------------------+  |
|  |  DAILY AVERAGE            | |  PROJECTED MONTHLY      |  |
|  |  1.45 GB / day            | |  43.5 GB                |  |
|  +---------------------------+ +-------------------------+  |
|  |  MOBILE / WI-FI RATIO     | |  PEAK USAGE DAY         |  |
|  |  22% Mobile • 78% Wi-Fi   | |  Wednesday (3.2 GB)     |  |
|  +---------------------------+ +-------------------------+  |
|                                                             |
+-------------------------------------------------------------+
|  [⚡ Dashboard]    [📱 Apps]    [📈 History]    [📋 Plan]   |
+-------------------------------------------------------------+
```

---

### Screen 4: Plan & Quota Manager

```
+-------------------------------------------------------------+
|  Data Plan Settings                                         |
+-------------------------------------------------------------+
|                                                             |
|  +-------------------------------------------------------+  |
|  |  ACTIVE CARRIER CONNECTION                            |  |
|  |  Carrier: Jio 5G (SIM 1)                              |  |
|  |  Status: Primary Mobile Data Network                  |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  PLAN CONFIGURATION:                                        |
|  • Quota Size: [ 5.0 ] [ GB ▼ ]                             |
|  • Cycle Type: (● Monthly)   (○ Daily)   (○ 28-Day Prepaid) |
|  • Reset Day:  Day [ 1 ] of each month                      |
|  • Alert Threshold: [ 80% ]                                 |
|    "Notify me when remaining data drops below 20%"           |
|                                                             |
|  +-------------------------------------------------------+  |
|  |  PLAN USAGE SUMMARY                                   |  |
|  |  • Consumed: 3.40 GB / 5.00 GB                        |  |
|  |  • Remaining: 1.60 GB                                 |  |
|  |  • Days Left in Cycle: 12 Days                        |  |
|  |  • Recommended Daily Allowance: ~133 MB / day         |  |
|  +-------------------------------------------------------+  |
|                                                             |
+-------------------------------------------------------------+
|  [⚡ Dashboard]    [📱 Apps]    [📈 History]    [📋 Plan]   |
+-------------------------------------------------------------+
```

---

### Screen 5: Settings & Status Bar Indicator

```
+-------------------------------------------------------------+
|  Settings                                                   |
+-------------------------------------------------------------+
|  STATUS BAR & NOTIFICATION                                  |
|  • Live Speed Indicator in Status Bar             [ ON / OFF]
|    Show continuous download & upload rate in shade          |
|  • Sampling Rate:  (○ 1.0s)   (● 1.5s)   (○ 2.0s)   (○ 3.0s)|
|  • Speed Units:    (● MB/s & KB/s)       (○ Mbps & Kbps)    |
|                                                             |
|  BATTERY SAVER (Zero-Waste)                                 |
|  • Auto-Pause when Screen is Off                     [Active]|
|    Live speed polling immediately suspends when device       |
|    display sleeps to prevent any pocket battery drain.      |
|                                                             |
|  PERMISSIONS STATUS                                         |
|  • Usage Access (PACKAGE_USAGE_STATS)           [Granted 🟢]|
|  • Phone State (Carrier Detection)             [Granted 🟢]|
|  • Notifications (Android 13+)                 [Granted 🟢]|
|                                                             |
|  PRIVACY & DATA                                             |
|  • 100% On-Device Guarantee: No analytics, no ads, no       |
|    remote network egress. All data stays in your sandbox.   |
+-------------------------------------------------------------+
```

---

## 3. Home Screen Widget Visual Layout

```
+-------------------------------------------------------+
|  ByteFlow                     [Jio 5G]         12:30  |
|                                                       |
|  Today: 428 MB Mobile        1.8 GB Wi-Fi             |
|                                                       |
|  Plan: [███████████████████░░░░░░░░░░]  68%           |
|  1.6 GB remaining of 5.0 GB  •  12 days left          |
+-------------------------------------------------------+
```

---

## 4. Micro-Interactions & Feedback

1. **Live Speed Pulse**:
   - Small glowing green/teal pulse dot next to the download/upload speed on the dashboard that throbs synchronously with active data transmission.
2. **Haptic Touch**:
   - Light haptic feedback when changing date filters or adjusting plan sliders.
3. **Smooth Progress Gauges**:
   - Animated easing curves (`Curves.easeOutCubic`) when the plan progress circle loads or updates.
4. **App Drill-Down Animation**:
   - Tapping an app smoothly transitions into a detailed bottom sheet showing hourly breakdowns and app info shortcuts.
