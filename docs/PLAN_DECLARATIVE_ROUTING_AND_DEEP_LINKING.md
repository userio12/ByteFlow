# Technical Specification & Architecture: Declarative Routing & Deep Linking (`go_router`)

> **Mode**: Strict Planning & Documentation Mode  
> **Status**: Awaiting User Approval to Start Implementation  
> **Target Subsystems**: Flutter Core Routing (`lib/core/router/`), Root App (`lib/main.dart`), Adaptive Shell (`AdaptiveScaffold`), Android Deep Linking (`AndroidManifest.xml`).  

---

## 1. Goal Description

Migrate ByteFlow's navigation architecture from legacy imperative `Navigator.push` and manual stateful tab switching to a **declarative, type-safe routing architecture powered by `go_router`**.

### Current Navigation Limitations in ByteFlow
1. **Imperative & Fragile**: Screens are opened with inline `Navigator.of(context).push(MaterialPageRoute(...))`, making deep linking, back navigation, and multi-tier routing difficult to maintain.
2. **Tab State Inefficiency**: `MainNavigationHost` manually manages an `_currentIndex` integer and rebuilds all 4 tabs via a list without formal branch isolation.
3. **No Deep Linking**: Notifications, home screen widgets, and system shortcuts cannot route directly into specific tabs or settings views (e.g., clicking a quota notification cannot deep link directly into `/plan`).
4. **Onboarding Routing Coupling**: `AppRootRouter` relies on a local boolean check in `initState` rather than declarative router redirection guards.

### Objectives of the Declarative Routing Architecture
1. **Declarative Navigation Tree**: Centralized `GoRouter` configuration in `lib/core/router/app_router.dart`.
2. **Persistent Bottom Shell (`StatefulShellRoute.indexedStack`)**: Implements separate navigation branches for Dashboard, App Usage, History, and Plan tabs, maintaining scroll position and view-model state across tab switches.
3. **Declarative Auth/Onboarding Guard**: Automatic router-level redirection to `/onboarding` if the user has not completed onboarding.
4. **System & Notification Deep Linking**:
   - Support `byteflow://` URI scheme (e.g. `byteflow://dashboard`, `byteflow://plan`, `byteflow://settings/live-speed`).
   - Seamlessly link native Android ongoing notification action buttons and data quota alert notifications to destination screens.
5. **Full Backward Compatibility & Zero Test Regression**: All existing 149 test suites continue to pass.

---

## 2. Route Architecture & URI Hierarchy

```
                                    +-----------------------+
                                    |       GoRouter        |
                                    +-----------------------+
                                                |
               +--------------------------------+--------------------------------+
               |                                                                 |
    [Root Route: /onboarding]                                     [StatefulShellRoute: /]
    (Guarded via redirect)                                        (Wraps AdaptiveScaffold)
                                                                                 |
                         +-----------------------+-----------------------+-------+---------------+
                         |                       |                       |                       |
                    [Branch 0]              [Branch 1]              [Branch 2]              [Branch 3]
                   /dashboard                 /apps                  /history                 /plan
                         |
           +-------------+-------------+
           |                           |
       /settings               /settings/live-speed
```

### Route Registry Table

| Route Path | Named Route | Screen Widget | Presentation Type | Deep Link URI |
| :--- | :--- | :--- | :--- | :--- |
| `/onboarding` | `AppRoutes.onboarding` | `OnboardingView` | Full Screen | `byteflow://onboarding` |
| `/dashboard` | `AppRoutes.dashboard` | `DashboardView` | Shell Tab (Index 0) | `byteflow://dashboard` |
| `/apps` | `AppRoutes.apps` | `AppUsageView` | Shell Tab (Index 1) | `byteflow://apps` |
| `/history` | `AppRoutes.history` | `HistoryView` | Shell Tab (Index 2) | `byteflow://history` |
| `/plan` | `AppRoutes.plan` | `PlanView` | Shell Tab (Index 3) | `byteflow://plan` |
| `/settings` | `AppRoutes.settings` | `SettingsView` | Full Screen Modal/Push | `byteflow://settings` |
| `/settings/live-speed` | `AppRoutes.liveSpeed` | `LiveSpeedSettingsView` | Full Screen Push | `byteflow://settings/live-speed` |
| `/settings/plan` | `AppRoutes.planSettings`| `DataPlanSettingsView` | Full Screen Push | `byteflow://settings/plan` |

---

## 3. Workflow & Implementation Plan

### Phase 1: Dependency & Route Registry
1. Add `go_router` to `pubspec.yaml` (e.g. `^14.8.1`).
2. Create `lib/core/router/app_routes.dart` defining static route paths and route names.

### Phase 2: Router Configuration & Redirection Engine
1. Create `lib/core/router/app_router.dart`:
   - Configures root `GoRouter` instance.
   - Implements `redirect` logic:
     ```dart
     redirect: (BuildContext context, GoRouterState state) {
       final prefs = context.read<LocalPreferencesService>();
       final isOnboardingDone = prefs.getOnboardingCompleted();
       final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

       if (!isOnboardingDone && !isOnboardingRoute) {
         return AppRoutes.onboarding;
       }
       if (isOnboardingDone && isOnboardingRoute) {
         return AppRoutes.dashboard;
       }
       return null;
     }
     ```
   - Configures `StatefulShellRoute.indexedStack` with 4 `StatefulShellBranch` branches for the primary navigation tabs.

### Phase 3: Shell Integration with `AdaptiveScaffold`
1. Adapt `AdaptiveScaffold` or create `ScaffoldWithNavShell` to consume `StatefulNavigationShell`:
   ```dart
   void _onDestinationSelected(int index) {
     navigationShell.goBranch(
       index,
       initialLocation: index == navigationShell.currentIndex,
     );
   }
   ```
2. Cleanly preserves tab state, scroll offsets, and active filter states without recreating view instances.

### Phase 4: App Entrypoint Modernization (`lib/main.dart`)
1. Replace `MaterialApp(home: const AppRootRouter())` with `MaterialApp.router(routerConfig: appRouter)`.
2. Migrate imperative navigation calls:
   - `onNavigateToApps: () => context.go(AppRoutes.apps)`
   - `onNavigateToPlan: () => context.go(AppRoutes.plan)`
   - `onOpenSettings: () => context.push(AppRoutes.settings)`

### Phase 5: Android Platform Deep Linking
1. Configure `android/app/src/main/AndroidManifest.xml` inside `<activity android:name=".MainActivity">`:
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="byteflow" />
   </intent-filter>
   ```
2. Allows testing deep link navigation via ADB:
   ```bash
   adb shell 'am start -a android.intent.action.VIEW -d "byteflow://plan"' com.byteflow
   ```

---

## 4. Proposed File Changes Grouped by Component

### A. Dependencies & Build Configuration
#### `[MODIFY]` `pubspec.yaml`
- Add dependency:
  ```yaml
  dependencies:
    go_router: ^14.8.1
  ```

---

### B. Core Routing Layer (`lib/core/router/`)
#### `[NEW]` `lib/core/router/app_routes.dart`
- Constants for named routes and route paths:
  ```dart
  abstract final class AppRoutes {
    static const String root = '/';
    static const String onboarding = '/onboarding';
    static const String dashboard = '/dashboard';
    static const String apps = '/apps';
    static const String history = '/history';
    static const String plan = '/plan';
    static const String settings = '/settings';
    static const String liveSpeed = '/settings/live-speed';
    static const String planSettings = '/settings/plan';
  }
  ```

#### `[NEW]` `lib/core/router/app_router.dart`
- Factory creating the configured `GoRouter`:
  - `GlobalKey<NavigatorState>` root and shell keys.
  - StatefulShellRoute with 4 branches (`DashboardView`, `AppUsageView`, `HistoryView`, `PlanView`).
  - Full-screen push routes for `SettingsView`, `LiveSpeedSettingsView`, and `DataPlanSettingsView`.
  - Guarded redirection based on `LocalPreferencesService.getOnboardingCompleted()`.

---

### C. Presentation & Main Host (`lib/`)
#### `[MODIFY]` `lib/main.dart`
- Bind `MaterialApp.router` with `routerConfig: createRouter(context)`.
- Deprecate old imperative `AppRootRouter` and `MainNavigationHost`.

#### `[MODIFY]` `lib/ui/core/widgets/adaptive_scaffold.dart`
- Support receiving `StatefulNavigationShell` for declarative branch switching while retaining existing desktop/mobile adaptive layouts.

---

### D. Android Subsystem (`android/app/src/main/`)
#### `[MODIFY]` `AndroidManifest.xml`
- Register `byteflow://` deep linking intent-filter on `MainActivity`.

---

### E. Test Suites (`test/`)
#### `[NEW]` `test/widget/core/app_router_test.dart`
- Unit/Widget tests verifying:
  - Unauthenticated/Non-onboarded user redirects to `/onboarding`.
  - Onboarded user lands on `/dashboard`.
  - Branch switching preserves state across tabs.
  - Deep link `byteflow://plan` navigates directly to Plan tab.
  - Deep link `byteflow://settings` opens Settings view.

---

## 5. Verification Plan

### Automated Tests
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run router test suite
flutter test test/widget/core/app_router_test.dart

# 3. Run all existing tests (149+ test suites must pass)
flutter test

# 4. Run static analysis
flutter analyze
```

### Manual Verification
1. **Clean Installation / Fresh State**:
   - Launch app -> confirm router routes to `/onboarding`.
   - Complete onboarding -> confirm router navigates to `/dashboard`.
2. **Branch Switching & State Preservation**:
   - Scroll down on App Usage tab -> switch to Dashboard -> switch back to App Usage -> verify scroll position is preserved.
3. **Deep Linking via ADB**:
   - Run: `adb shell 'am start -a android.intent.action.VIEW -d "byteflow://plan"' com.byteflow`
   - Verify app opens directly to Plan tab.
   - Run: `adb shell 'am start -a android.intent.action.VIEW -d "byteflow://settings/live-speed"' com.byteflow`
   - Verify app opens directly into Live Speed Settings view.

---

## 6. Execution Safeguard

> [!IMPORTANT]
> **Strict Planning Mode Active**:
> This document serves as the formal design and specification. No code, dependencies, or configuration files will be modified until you review and grant explicit approval to proceed with implementation.
