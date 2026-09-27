# ByteFlow — System Architecture & Design Specification

> **Governed by Official Flutter Agent Skills**:
> - [`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md): MVVM Layered Architecture & Separation of Concerns.
> - [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md): Adaptive LayoutBuilder & Window Sizing.
> - [`flutter-hot-reload`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/rules/flutter-hot-reload.md): Stateful preservation during development.

---

## 1. Executive Summary & Core Tenets

**ByteFlow** is a lightweight, privacy-first Android application designed to track mobile data and Wi-Fi usage, support automatic active carrier detection, provide historical analytics with peak spike detection, display home screen widgets, and show a battery-optimized live speed indicator in the status bar.

### Core Tenets
1. **100% On-Device Privacy**: No analytics SDKs, no external telemetry, no remote servers. All network accounting data is read directly from Android's local kernel accounting tables (`NetworkStatsManager` and `TrafficStats`).
2. **Zero-Waste Battery Architecture**:
   - The live status bar speed indicator dynamically pauses sampling when the screen turns off (`ACTION_SCREEN_OFF`), ensuring 0% CPU consumption in sleep or pocket mode.
   - Long-term statistics rely on Android's indexed usage database rather than continuous background packet capture or wake locks.
3. **Automatic Carrier & SIM Detection (No Manual Switching)**:
   - Automatic carrier and SIM card detection via `SubscriptionManager`.
   - Automatically binds to the active data subscription (`SubscriptionManager.getDefaultDataSubscriptionId()`).
   - No manual SIM switching required; tracks active mobile connection seamlessly.
4. **Native Android Integration**:
   - Native Material 3 Home Screen AppWidget (`AppWidgetProvider`).
   - Ongoing low-priority status bar speed indicator notification with live throughput rates.
   - Deep links into system Usage Access and Notification settings.
5. **Zero-Static Data & Dynamic Multi-Timeframes**:
   - 100% dynamic kernel polling across **Today (Hourly 24h)**, **Weekly (7d)**, **Monthly (30d / cycle)**, and **Yearly (12mo)**.
   - Zero mock data; genuine cold-start backfill from Android's `/data/system/netstats/` logs.

---

## 2. High-Level Architecture Diagram (Official Flutter MVVM & Layering)

```mermaid
flowchart TD
    subgraph Android_Native_Layer ["Android Native Subsystem (Kotlin)"]
        SM["SubscriptionManager<br/>• SIM Detection & Carrier Name<br/>• Active Data Subscription"]
        NSM["NetworkStatsManager<br/>• Total Cellular Usage<br/>• Total Wi-Fi Usage<br/>• Per-App Breakdown (UIDs)<br/>• FG vs BG Split<br/>• Time Bucket Slicing (24h/7d/30d/12mo)"]
        TS["TrafficStats + ScreenReceiver<br/>• Real-time Rx/Tx Throughput (B/s)<br/>• Screen ON/OFF Lifecycle"]
        FS["LiveSpeedService (Foreground Service)<br/>• Low-Priority Ongoing Notification<br/>• Live Speed: ↓ X MB/s  ↑ Y KB/s<br/>• Today's Mobile & Wi-Fi Summary"]
        WP["ByteFlowWidgetProvider (AppWidget)<br/>• Material 3 Home Screen Widget<br/>• Real-time Plan Progress"]
        MC["MethodChannel & EventChannel<br/>• 'com.byteflow/network_v1'<br/>• 'com.byteflow/speed_stream_v1'"]
    end

    subgraph Data_Layer ["Data Layer (flutter-apply-architecture-best-practices)"]
        NNS["NativeNetworkService<br/>(Stateless Platform Channel Wrapper)"]
        CSB["ColdStartBackfillService<br/>(Kernel Cache Ingestion)"]
        LDS["LocalDatabaseService<br/>(SQLite Time-Series DAOs)"]
        NR["NetworkRepositoryImpl<br/>(Single Source of Truth, Caching)"]
        PR["PlanRepositoryImpl<br/>(Quota & Cycle Configuration)"]
    end

    subgraph Domain_Layer ["Domain Layer (Pure Dart Business Logic)"]
        DM["Domain Models<br/>• TimeRange & UsageTimeBucket<br/>• HistoricalSummaryEntity<br/>• NetworkSummary & AppUsage<br/>• DataPlan & SimInfo"]
        UC1["GetTodayUsageUseCase"]
        UC2["GetHistoricalSummaryUseCase<br/>(Today/Week/Month/Year)"]
        UC3["GetAppBreakdownUseCase"]
        UC4["GetHourlySpikesUseCase"]
    end

    subgraph UI_Layer ["Presentation Layer (MVVM + Responsive Layouts)"]
        subgraph Dashboard_Feature ["Feature: Dashboard"]
            DVM["DashboardViewModel (ChangeNotifier)"]
            DV["DashboardView (ListenableBuilder)"]
        end
        subgraph Apps_Feature ["Feature: App Usage"]
            AVM["AppUsageViewModel (ChangeNotifier)"]
            AV["AppUsageView (Fixed itemExtent: 76.0)"]
        end
        subgraph History_Feature ["Feature: History & Spikes"]
            HVM["HistoryViewModel (ChangeNotifier)"]
            HV["HistoryView (fl_chart Multi-Timeframe)"]
        end
        subgraph Plan_Feature ["Feature: Plan Settings"]
            PVM["PlanViewModel (ChangeNotifier)"]
            PV["PlanView (RadialGauge)"]
        end
    end

    SM --> MC
    NSM --> MC
    TS --> FS
    FS --> MC
    WP <--> MC
    MC <--> NNS
    NNS --> NR
    LDS --> NR
    LDS --> PR
    NR --> UC1
    NR --> UC2
    NR --> UC3
    PR --> UC1
    UC1 --> DVM
    UC2 --> AVM
    UC3 --> HVM
    PR --> PVM
    DVM --> DV
    AVM --> AV
    HVM --> HV
    PVM --> PV
```

---

## 3. Privacy & Security Model

ByteFlow operates on a zero-trust external model:
- **No Remote Telemetry**: The app does not include any third-party advertising or analytics SDKs (e.g. Firebase, Mixpanel, Adjust).
- **No Network Egress**: The application does not send device usage, package lists, or telemetry outside the local device.
- **Local Persistence Only**: Settings, user quotas, and cached calculations are stored solely in Android's private app sandbox (`SQLite` / `SharedPreferences`).
- **System Permission Transparency**:
  - `PACKAGE_USAGE_STATS`: Declared with explicit onboarding rationale and opened via `Settings.ACTION_USAGE_ACCESS_SETTINGS`.
  - `READ_PHONE_STATE`: Used strictly for reading SIM card subscription metadata via `SubscriptionManager`.
  - `POST_NOTIFICATIONS`: Requested strictly on Android 13+ for the status bar live speed service.

---

## 4. Battery Optimization Strategy

Continuous background monitoring can easily drain device batteries if implemented naively. ByteFlow uses three key architectural measures:

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Android as Android OS
    participant Service as LiveSpeedService
    participant Screen as ScreenReceiver

    User->>Service: Enable Live Speed Indicator
    Service->>Android: Register ScreenReceiver (ACTION_SCREEN_ON / OFF)
    Service->>Service: Start 1.5s Sampling Loop (TrafficStats)
    Note over Service: Live Speed Updates Ongoing Notification
    
    Android->>Screen: ACTION_SCREEN_OFF (Display sleeps)
    Screen->>Service: Pause Sampling Loop
    Note over Service: 0% CPU Usage in Sleep Mode
    
    Android->>Screen: ACTION_SCREEN_ON (Display wakes)
    Screen->>Service: Take Baseline Snapshot & Resume Sampling Loop
    Service->>Service: Resume 1.5s Sampling Loop
```

1. **Screen-Aware Live Service**:
   - `LiveSpeedService` listens for `Intent.ACTION_SCREEN_OFF`. When the user locks the phone or puts it in a pocket, the timer loop is suspended immediately.
   - When `Intent.ACTION_SCREEN_ON` is received, the service captures a fresh baseline reading and resumes the timer loop.
2. **Kernel Accounting Reuse**:
   - Rather than intercepting packets with a local VPN (which keeps the CPU active and increases battery drain), ByteFlow reads historical statistics directly from Android's hardware accounting engine (`NetworkStatsManager`).
3. **Smart Home Screen Widget Updates**:
   - The home screen widget is updated on-demand when the app is opened, when data refreshes, or periodically via standard `AppWidgetProvider` update intervals (never keeping persistent wakelocks).
