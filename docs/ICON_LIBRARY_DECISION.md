# ByteFlow — Icon Library Evaluation & Architecture Decision Record (ADR)

This document provides a comparative technical evaluation of icon libraries for **ByteFlow**, assessing binary footprint, tree-shaking efficiency, telecom/network glyph coverage, and Material 3 design harmony.

---

## 1. Candidate Comparison Matrix

| Icon Library | Package / Source | Binary Size Impact | Tree-Shaking | Network/SIM Glyphs | Material 3 Harmony | Recommended For |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Material 3 Rounded (Built-in)** | `flutter/material.dart` | **0 KB (Included in SDK)** | **Yes (100% automated)** | **Comprehensive** (Cellular, Wi-Fi, SIM, Speed, Quota) | **Native 1:1 Match** | 🏆 **Primary Choice (Production Core)** |
| **Material Symbols Icons** | `material_symbols_icons` | ~60 KB (Tree-shaken) | Yes | **Exhaustive** (Every state of 5G, Wi-Fi 6, Roaming) | **Native 1:1 Match** (Google's latest variable font) | 🌟 **Top Alternative (For variable font weights)** |
| **Lucide Icons** | `lucide_icons` | ~120 KB (Tree-shaken) | Yes | Good (General network, arrows) | Modern / Minimalist line aesthetic | Clean SaaS / DevTools feel |
| **FontAwesome Flutter** | `font_awesome_flutter` | ~350 KB | Partial | Poor for Android system glyphs (Great for brand logos) | Mismatches Material 3 tokens | Not Recommended |
| **Remix Icon** | `remixicon` | ~180 KB | Yes | Moderate | Neutral / Web feel | Web / Desktop apps |

---

## 2. Technical Recommendation: Flutter Material 3 Rounded + Material Symbols

For an Android system-level network monitoring app, **Flutter Built-in Material 3 Rounded Icons** (`Icons.*_rounded`), complemented by **`material_symbols_icons`** where variable weights are needed, is the clear winner for five critical reasons:

### Reason 1: True Compiler-Level Tree Shaking & Zero APK Bloat
- When compiling an Android release build (`flutter build apk`), Flutter's AOT compiler scans the code and strips away every glyph that is not explicitly referenced.
- Using built-in icons introduces **0 new external package dependencies**, eliminates version resolution conflicts, and adds **under 35 KB** to the final APK.

### Reason 2: Perfect Telecom & Hardware Domain Coverage
Material Design was engineered by Google specifically for the Android OS ecosystem. It possesses the most exhaustive set of network hardware glyphs:

```dart
// Core ByteFlow Domain Glyphs (All natively available):
Icons.speed_rounded                  // Hero speedometer & live throughput
Icons.network_cell_rounded           // Cellular data active
Icons.signal_cellular_alt_rounded   // Mobile signal bars & carrier
Icons.sim_card_rounded              // Physical SIM card
Icons.sim_card_download_rounded     // eSIM profile
Icons.wifi_rounded                   // Wi-Fi network active
Icons.wifi_tethering_rounded        // Hotspot data sharing
Icons.data_usage_rounded            // Plan quota consumption
Icons.swap_vert_rounded             // Simultaneous Rx / Tx traffic
Icons.arrow_downward_rounded        // Download rate (Rx)
Icons.arrow_upward_rounded          // Upload rate (Tx)
Icons.battery_saver_rounded         // Screen-off battery saver mode
Icons.shield_rounded                // 100% On-device privacy badge
Icons.pie_chart_rounded             // Quota consumption ring
Icons.insights_rounded              // Hourly spikes & analytics
Icons.apps_rounded                  // App usage breakdown
```

### Reason 3: Consistency with Android System Status Bar & Widgets
- ByteFlow's Home Screen AppWidget and Foreground Notification exist inside Android's system surfaces (Status Bar, Notification Shade, Home Screen).
- Using Material 3 Rounded glyphs guarantees visual unity between the in-app UI and the Android system notification icons.

### Reason 4: Dynamic Color & Two-Tone Fill States
Material 3 icons cleanly support filled vs. outlined toggles:
- **Inactive Tab**: `Icons.speed_outlined` (Stroke with `onSurfaceVariant`)
- **Active Tab**: `Icons.speed_rounded` (Filled with `onSecondaryContainer` on stadium pill)

---

## 3. Implementation Blueprint in ByteFlow

```dart
// core/theme/app_icons.dart
abstract final class AppIcons {
  // Navigation
  static const dashboardActive = Icons.speed_rounded;
  static const dashboardInactive = Icons.speed_outlined;
  static const appsActive = Icons.apps_rounded;
  static const appsInactive = Icons.apps_outlined;
  static const historyActive = Icons.insights_rounded;
  static const historyInactive = Icons.insights_outlined;
  static const planActive = Icons.pie_chart_rounded;
  static const planInactive = Icons.pie_chart_outline_rounded;

  // Network Interfaces
  static const cellular = Icons.signal_cellular_alt_rounded;
  static const wifi = Icons.wifi_rounded;
  static const hotspot = Icons.wifi_tethering_rounded;
  static const simCard = Icons.sim_card_rounded;

  // Traffic Direction
  static const download = Icons.arrow_downward_rounded;
  static const upload = Icons.arrow_upward_rounded;
  static const trafficPulse = Icons.swap_vert_rounded;

  // Status & Diagnostics
  static const batterySaver = Icons.battery_saver_rounded;
  static const privacyShield = Icons.shield_rounded;
  static const alertWarning = Icons.warning_amber_rounded;
  static const checkCircle = Icons.check_circle_rounded;
  static const settings = Icons.settings_rounded;
}
```
