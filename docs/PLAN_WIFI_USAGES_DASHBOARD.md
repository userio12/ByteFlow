# Plan: Fix & Elevate Wi-Fi Usages on Dashboard

> **Document Status**: Pending User Approval  
> **Target Scope**: Dashboard UI, Dashboard ViewModel, Native Android `NetworkStatsHelper`, and Dependency Injection.

---

## 1. Executive Summary & Root Cause Analysis

### Question: "Why in Dashboard is it showing only mobile data usages and why not Wi-Fi usages?"

Through a comprehensive audit of the Flutter presentation layer, ViewModel state management, and native Android `NetworkStatsManager` queries, we identified **three primary root causes**:

```
+----------------------------------------------------------------------------------------------------+
|                                    ROOT CAUSE ARCHITECTURE                                         |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
| 1. DASHBOARD UI CENTERPIECE HARDCODED TO MOBILE                                                    |
|    - DashboardView -> PlanProgressRing:                                                            |
|      usedMobileBytes: summary.mobileTotal                                                          |
|      plan: vm.dataPlan (Cellular only)                                                             |
|    - The large gauge occupying >50% of the screen ONLY calculates & displays Cellular bytes.       |
|    - Wi-Fi has a full data plan entity and repository in the app, but DashboardViewModel          |
|      never loads it and provides NO toggle between Cellular and Wi-Fi.                              |
|                                                                                                    |
| 2. ANDROID NATIVE SUBSYSTEM WI-FI QUERY QUIRK (NetworkStatsHelper.kt)                               |
|    - Line 156: nsm.querySummaryForDevice(ConnectivityManager.TYPE_WIFI, null, start, end)          |
|    - For TYPE_MOBILE, subscriberId=null matches all carriers.                                      |
|    - For TYPE_WIFI, Android AOSP/OEMs (Samsung OneUI, Xiaomi MIUI, ColorOS) expect subscriberId=""  |
|      (empty string) because Wi-Fi has no IMSI. Passing null throws IllegalArgumentException.       |
|    - NetworkStatsHelper catches this with an empty `catch (_: Exception) {}`, silently resetting   |
|      wifiRx = 0L and wifiTx = 0L. As a result, DailyComparisonTile shows 0 B on many devices.      |
|                                                                                                    |
| 3. SPEED PULSE CARD LACKS INTERFACE IDENTIFIER                                                     |
|    - SpeedPulseCard displays live throughput without indicating whether the active connection      |
|      is Wi-Fi or Cellular (as specified in docs/WIFI_USAGE_SPEC.md).                                |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. Proposed Architectural Solution

### A. Native Android Kernel Query Hardening
In [`NetworkStatsHelper.kt`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/android/app/src/main/kotlin/com/byteflow/network/NetworkStatsHelper.kt):
Implement a resilient dual-query fallback for `ConnectivityManager.TYPE_WIFI`:
1. First query with `""` (the standard AOSP Wi-Fi subscriberId).
2. If that fails or throws, fallback to `null`.
3. Apply this fallback across `queryDeviceTotal`, `queryAppsUsage`, and `queryTimeBuckets`.

### B. Dashboard ViewModel Enhancement
In [`DashboardViewModel.dart`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/lib/ui/features/dashboard/view_models/dashboard_view_model.dart):
1. Inject `IPlanRepository` into `DashboardViewModel`.
2. Load both `_cellularPlan` and `_wifiPlan`.
3. Add `PlanCategory _selectedCategory = PlanCategory.cellular;` (Cellular vs. Wi-Fi).
4. Provide active properties:
   - `PlanCategory get selectedCategory => _selectedCategory;`
   - `DataPlanEntity get activePlan => _selectedCategory == PlanCategory.cellular ? _cellularPlan : _wifiPlan;`
   - `int get activeUsedBytes => _selectedCategory == PlanCategory.cellular ? (_todaySummary?.mobileTotal ?? 0) : (_todaySummary?.wifiTotal ?? 0);`
5. Provide user action `void selectCategory(PlanCategory category)` to switch the dashboard centerpiece smoothly.

### C. Dashboard UI Enhancements
1. **Interactive Category Selector on Dashboard**:
   - Add a sleek `SegmentedButton<PlanCategory>` or Category Tabs above the `PlanProgressRing` (or inside the card header):
     - `[Cellular 📶]` | `[Wi-Fi 🌐]`
   - Toggling changes the radial gauge, used quota, remaining quota, days left, and budget pace between Cellular mobile data and Wi-Fi broadband/hotspot quotas.
2. **Interactive Daily Comparison Tile**:
   - Allow tapping on the `Cellular` or `Wi-Fi` card in `DailyComparisonTile` to dynamically switch the active plan view or highlight the selected category.
3. **SpeedPulseCard Interface Awareness**:
   - Detect whether current active throughput is flowing via Wi-Fi or Cellular and show an active badge: e.g. `Wi-Fi Active 📶` or `Cellular Active 📶`.

---

## 3. Implementation Step-by-Step

### Phase 1: Native Subsystem Robustness
- Modify [`android/app/src/main/kotlin/com/byteflow/network/NetworkStatsHelper.kt`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/android/app/src/main/kotlin/com/byteflow/network/NetworkStatsHelper.kt)
  - Safe Wi-Fi query helper with `""` and `null` fallback.
  - Logging unexpected exceptions instead of swallowing them blindly.

### Phase 2: Dependency Injection & Repositories
- Update [`lib/core/di/dependency_injection.dart`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/lib/core/di/dependency_injection.dart)
  - Provide `IPlanRepository` to `DashboardViewModel`.

### Phase 3: Dashboard ViewModel
- Update [`lib/ui/features/dashboard/view_models/dashboard_view_model.dart`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/lib/ui/features/dashboard/view_models/dashboard_view_model.dart)
  - Fetch `_planRepository.getWifiPlan()` alongside `getDataPlanUseCase()`.
  - Add category switching logic (`selectCategory`).

### Phase 4: UI Components
- Update [`lib/ui/features/dashboard/widgets/plan_progress_ring.dart`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/lib/ui/features/dashboard/widgets/plan_progress_ring.dart)
  - Support displaying Wi-Fi plan labels, Wi-Fi icon, and customizable category indicators.
- Update [`lib/ui/features/dashboard/widgets/daily_comparison_tile.dart`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/lib/ui/features/dashboard/widgets/daily_comparison_tile.dart)
  - Support tap callbacks (`onSelectCellular`, `onSelectWifi`) and active selection state border/glow.
- Update [`lib/ui/features/dashboard/views/dashboard_view.dart`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/lib/ui/features/dashboard/views/dashboard_view.dart)
  - Add category toggle or integrate seamless switching.

### Phase 5: Verification & Unit/Widget Tests
- Update and extend unit and widget tests:
  - `test/unit/ui/dashboard_view_model_test.dart` (or `test/widget/features/dashboard_view_test.dart`)
  - Verify category switching, Wi-Fi usage display, and metric calculations.
  - Run full test suite: `flutter test`.

---

## 4. Approval Gate
> **Action Required**: This plan is stored in the project directory as requested (`docs/PLAN_WIFI_USAGES_DASHBOARD.md`).  
> **Status**: Pausing and waiting for user approval before modifying code files.
