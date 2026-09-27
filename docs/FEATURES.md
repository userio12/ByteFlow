# ByteFlow — Feature Specification List

This document provides a comprehensive list of all planned features for **ByteFlow**, organized by domain.

---

## 1. Core Network & Data Monitoring (100% Dynamic, Zero-Static Data)

- **Zero-Static Data Mandate**: Strict rejection of synthetic placeholders or hardcoded mock data. Every single byte, speed, app entry, and chart point is pulled directly from Android Linux kernel tables (`NetworkStatsManager`, `TrafficStats`), `SubscriptionManager`, and local SQLite time-series rollups.
- **Real-Time Cellular & Wi-Fi Tracking**: Continuous, accurate tracking of mobile data and Wi-Fi network traffic, broken down into download (Rx) and upload (Tx) bytes.
- **Accurate Kernel Hardware Accounting**: Integrates directly with Android's `NetworkStatsManager` to read hardware-level socket metrics without battery-draining VPN overhead.
- **Granular Multi-Timeframe Engine**:
  - **Today / Hourly**: 24-hour slices (`00:00`–`23:59`), peak spike culprit identification, and live delta polling.
  - **Weekly**: Rolling 7-day or Mon–Sun comparative bars, day-over-day burn rates, and Wi-Fi offload ratios.
  - **Monthly**: Current billing cycle (1st to 28th/31st) cumulative consumption trajectory vs ideal linear pace.
  - **Yearly**: 12-month historical breakdown (Jan–Dec), seasonal trends, and total annual carrier vs Wi-Fi offload.
- **Cold-Start Kernel Backfill**: On first launch, automatically backfills historical trends from OS logs stored in `/data/system/netstats/`, ensuring genuine history from day one without mock data.

---

## 2. Automatic Carrier & SIM Detection (No Manual Switching)

- **Zero-Friction Automatic SIM Detection**: Automatically identifies active physical SIM and eSIM cards via Android's `SubscriptionManager`.
- **Automatic Active Data SIM Binding**: Automatically recognizes which SIM is handling the device's active mobile data traffic (`SubscriptionManager.getDefaultDataSubscriptionId()`) and tracks usage against it automatically.
- **No Manual Switching Required**: Eliminates manual SIM switching tabs or selectors. The UI seamlessly adapts to whichever SIM is providing data.
- **Carrier & Network Badge**: Clean, informational badge displaying the active carrier (e.g., `Jio 5G (SIM 1)` or `Airtel 4G (SIM 2)`).
- **Unified Mobile Data Plan**: Simple, clear plan tracking for your active mobile connection with custom quota, reset day, and low-data warning alerts.

---

## 3. History, Trends & Multi-Timeframe Analytics

- **Hourly Usage Spikes (Today)**:
  - Visual 24-hour timeline bar chart detailing hourly data consumption.
  - Identifies peak spike periods (e.g. video streaming at 3:00 PM or cloud backup at night) and highlights the culprit app.
- **Weekly Trend Comparison (Past 7 Days)**:
  - Grouped and stacked bar charts comparing Cellular vs Wi-Fi day-by-day.
  - Day-over-day consumption change analysis and heaviest day flag.
- **Monthly Trajectory & Burn Rate (Billing Cycle)**:
  - Cumulative consumption line graph mapped against the ideal linear allowance line.
  - Early exhaustion warning if current burn pace exceeds remaining monthly days.
- **Yearly Historical Breakdown (Past 12 Months)**:
  - High-level 12-month bar chart showing annual cellular vs Wi-Fi distribution and seasonal shifts.
- **Usage Insights & Projections**:
  - Dynamic average daily consumption rate.
  - Estimated days remaining before plan quota exhaustion.
  - Total cellular data saved via Wi-Fi offload percentage.

---

## 4. Per-App Data Breakdown & Diagnostics

- **Full Application Inventory**: Lists every installed and system application that consumed network data during the selected timeframe.
- **App Identification**: Shows the official application icon, human-readable app label, and package ID.
- **Foreground vs Background Split**:
  - Explicitly separates data used while the app was actively open on screen (Foreground) from data consumed silently in the background (Background).
  - Flags "Data Hogs" running covertly in the background.
- **Interactive Search & Sorting**:
  - Instant text search by app name.
  - Sort by: Total Data, Download, Upload, Background Usage, or Alphabetical.
- **Relative Consumption Bars**: Visual percentage progress bars relative to the highest consuming app.

---

## 5. Live Status Bar Speed Indicator & Service

- **Real-Time Network Speed**:
  - Ongoing, low-priority status bar notification displaying live download and upload rates (e.g., `↓ 2.4 MB/s  ↑ 180 KB/s`).
- **Notification Summary Card**:
  - Shows current day's cellular and Wi-Fi total directly inside the notification drawer.
  - Displays active carrier badge.
  - Quick action button to launch ByteFlow.
- **Configurable Refresh Intervals**: Choose between 1.0s, 1.5s, 2.0s, or 3.0s sampling rates.
- **Format Preferences**: Toggle between Bytes/second (`KB/s`, `MB/s`) and Bits/second (`Kbps`, `Mbps`).

---

## 6. Zero-Waste Battery Architecture

- **Display-Aware Lifecycle**:
  - Registers a native broadcast receiver for `Intent.ACTION_SCREEN_OFF` and `Intent.ACTION_SCREEN_ON`.
  - When the screen turns off (phone locked or in pocket), live speed sampling is **instantly paused**, reducing CPU consumption to 0%.
  - When the screen wakes up, a baseline snapshot is taken and sampling resumes smoothly.
- **No Background VPN or Packet Sniffing**: Relies on Android's internal accounting tables (`NetworkStatsManager`), eliminating the high battery drain and thermal throttling of VPN-based monitors.
- **Zero Wakelocks**: No persistent CPU wake locks or background alarm loops.

---

## 7. Home Screen Widgets (AppWidget)

- **Material 3 Design**: Clean surface container with adaptive rounded corners matching Android system theming.
- **Glanceable Metrics**:
  - Active carrier name badge.
  - Today's Mobile Data vs Wi-Fi Data.
  - Plan usage progress gauge (% used of current plan).
  - Remaining data allowance for the current cycle.
- **Interactive Launch**: Tap widget to open the full ByteFlow dashboard.
- **Smart Update Policy**: Refreshes on app open, data state changes, or periodic system intervals.

---

## 8. 100% On-Device Privacy & Security

- **Zero Remote Telemetry**: No external servers, no Google Analytics, no Firebase, no advertising trackers.
- **Local Data Processing**: All calculations, chart buckets, and plan limits are processed and stored locally on the device in private app storage.
- **Permission Transparency**: Clear, user-friendly in-app explanations for why Android's `PACKAGE_USAGE_STATS` (Usage Access) and `READ_PHONE_STATE` (SIM detection) are needed.

---

## 9. Modern Material 3 UI / UX

- **Dynamic Color Harmonization**: Seamlessly adapts to your Android 12+ wallpaper accent colors via `dynamic_color`.
- **Dark & Light Modes**: High-contrast OLED dark mode and clean light mode.
- **Streamlined Navigation**:
  1. **Dashboard**: Live speed card, active carrier badge, plan gauge, and quick daily overview.
  2. **Apps**: Granular per-app rankings, search, and foreground/background inspector.
  3. **History**: Interactive charts for hourly spikes and weekly trends.
  4. **Plans**: Plan quota setup, reset dates, and alerts.
  5. **Settings**: Live indicator toggles, widget configuration, and privacy status.
