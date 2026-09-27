# ByteFlow — Full Detailed Project Architecture & Complete File Tree

> **Architectural Standard**: Senior Mobile Systems Architect Blueprint  
> **Framework Standard**: Official Flutter Agent Skills ([`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md), [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md))

This document provides the **100% exhaustive, fully expanded tree view** of every single file, folder, class, and component across Flutter (Dart), Android Native (Kotlin), Resources (XML), Tests, Skills, Rules, and Docs.

---

## 1. Complete Master Project Tree (Every File Accounted For)

```
ByteFlow/
│
├── .agents/                                       # Official AI Agent Plugins & Skills
│   ├── rules/
│   │   ├── flutter-hot-reload.md                  # State preservation guidelines during development
│   │   └── flutter-hot-reload.mdc                 # Cached rule metadata
│   └── skills/                                    # 25 Official Google/Flutter Team Skills + Graphify
│       ├── dart-add-unit-test/                    # package:test unit testing standards
│       ├── dart-build-cli-app/
│       ├── dart-collect-coverage/
│       ├── dart-fix-runtime-errors/
│       ├── dart-generate-test-mocks/
│       ├── dart-migrate-to-checks-package/
│       ├── dart-resolve-package-conflicts/
│       ├── dart-run-static-analysis/
│       ├── dart-setup-ffi-assets/
│       ├── dart-use-doc-examples/
│       ├── dart-use-ffigen/
│       ├── dart-use-path-package/
│       ├── dart-use-pattern-matching/
│       ├── dart-use-primary-constructors/
│       ├── dart-write-documentation/
│       ├── flutter-add-integration-test/
│       ├── flutter-add-widget-preview/
│       ├── flutter-add-widget-test/              # Component-level UI and ViewModel test rules
│       ├── flutter-apply-architecture-best-practices/ # MVVM + Repository Layering
│       ├── flutter-build-responsive-layout/       # LayoutBuilder, MediaQuery.sizeOf, ConstrainedBox
│       ├── flutter-fix-layout-issues/             # Defenses against RenderFlex overflows
│       ├── flutter-implement-json-serialization/  # DTO pattern-matched serialization
│       ├── flutter-setup-declarative-routing/
│       ├── flutter-setup-localization/            # arb-based internationalization
│       ├── flutter-use-http-package/
│       └── graphify/                              # Local AST knowledge graph intelligence
│
├── android/                                       # Native Android Subsystem (Kotlin & Gradle)
│   ├── gradle/wrapper/
│   │   ├── gradle-wrapper.jar
│   │   └── gradle-wrapper.properties
│   ├── app/
│   │   ├── build.gradle.kts                       # App module Gradle build file (Kotlin DSL)
│   │   ├── proguard-rules.pro                     # R8/Proguard code minification rules
│   │   └── src/main/
│   │       ├── AndroidManifest.xml                # Manifest (Permissions, Services, Widgets)
│   │       ├── kotlin/com/byteflow/
│   │       │   ├── MainActivity.kt                # FlutterActivity & Platform Channel registry
│   │       │   ├── network/
│   │       │   │   ├── NetworkStatsHelper.kt      # NetworkStatsManager & SubscriptionManager
│   │       │   │   ├── NetworkChannelHandler.kt   # Coroutine-backed MethodCallHandler
│   │       │   │   └── IconCacheHelper.kt         # Native LruCache downsampling app icons (OOM guard)
│   │       │   ├── service/
│   │       │   │   ├── LiveSpeedService.kt        # Foreground service computing TrafficStats delta
│   │       │   │   ├── ScreenReceiver.kt          # ACTION_SCREEN_OFF 0% battery saver listener
│   │       │   │   └── SpeedNotificationHelper.kt # Silent ongoing status bar notification
│   │       │   ├── widget/
│   │       │   │   └── ByteFlowWidgetProvider.kt  # Material 3 Home Screen AppWidget RemoteViews
│   │       │   └── model/
│   │       │       ├── AppUsageRecord.kt          # Native data class for per-app statistics
│   │       │       ├── NetworkTotalRecord.kt      # Native data class for device totals
│   │       │       └── SimRecord.kt               # Native data class for SIM & Carrier metadata
│   │       └── res/
│   │           ├── drawable/
│   │           │   ├── launch_background.xml      # Splash screen drawable
│   │           │   ├── widget_background.xml      # Material 3 rounded card background for widget
│   │           │   └── widget_progress_bar.xml    # Custom XML progress drawable for widget
│   │           ├── layout/
│   │           │   └── widget_byteflow.xml        # RemoteViews XML layout for home screen widget
│   │           ├── xml/
│   │           │   └── byteflow_widget_info.xml   # AppWidget provider metadata configuration
│   │           └── values/
│   │               ├── colors.xml                 # Native widget color tokens
│   │               ├── strings.xml                # Native widget strings & notification channel name
│   │               └── styles.xml                 # Window launch styles & normal themes
│   ├── build.gradle.kts                           # Root Gradle build script
│   ├── settings.gradle.kts                        # Plugin repositories & Flutter tool include
│   ├── gradle.properties                          # JVM args, AndroidX, and build optimizations
│   └── local.properties                           # Local SDK directory pointers
│
├── lib/                                           # Flutter Application Source Tree
│   ├── main.dart                                  # App bootstrap, DynamicColorBuilder & MultiProvider
│   │
│   ├── l10n/                                      # Internationalization (flutter-setup-localization)
│   │   ├── app_en.arb                             # English localization source template
│   │   ├── app_localizations.dart                 # Generated localization delegate class
│   │   └── app_localizations_en.dart              # Generated English message lookup
│   │
│   ├── core/                                      # Cross-Cutting Core Architecture
│   │   ├── constants/
│   │   │   ├── app_constants.dart                 # Default limits, refresh rates, threshold defaults
│   │   │   ├── channel_constants.dart             # Channel names: 'com.byteflow/network_v1'
│   │   │   └── storage_keys.dart                  # SharedPreferences & SQLite key constants
│   │   ├── errors/
│   │   │   ├── app_failure.dart                   # Typed sealed failure hierarchy
│   │   │   └── exceptions.dart                    # Low-level platform & database exceptions
│   │   ├── functional/
│   │   │   └── result.dart                        # Result<Success, AppFailure> monad
│   │   ├── theme/
│   │   │   ├── app_theme.dart                     # Material 3 Light & OLED Dark Theme configuration
│   │   │   ├── app_colors.dart                    # Monet dynamic color harmonization helpers
│   │   │   ├── app_typography.dart                # DisplayLarge down to LabelSmall type scale
│   │   │   └── app_icons.dart                     # Centralized Material 3 rounded icon registry
│   │   ├── utils/
│   │   │   ├── byte_formatter.dart                # B, KB, MB, GB, TB conversion with precision
│   │   │   ├── date_utils.dart                    # Billing cycle reset math & 24-hr time buckets
│   │   │   └── platform_utils.dart                # Device platform & API level inspection
│   │   └── di/
│   │       └── dependency_injection.dart          # MultiProvider registration graph
│   │
│   ├── domain/                                    # Pure Dart Domain Layer (Zero Framework Bloat)
│   │   ├── models/                                # Immutable Domain Entities
│   │   │   ├── time_range.dart                    # Enum: today, week, month, year with date bounds
│   │   │   ├── usage_time_bucket.dart             # Discrete time bucket with mobile/wifi rx/tx
│   │   │   ├── historical_summary_entity.dart     # Multi-timeframe aggregated statistics & offload %
│   │   │   ├── app_usage_entity.dart              # UID, packageName, appName, FG/BG bytes
│   │   │   ├── network_summary_entity.dart        # Mobile vs Wi-Fi totals, Rx/Tx split
│   │   │   ├── data_plan_entity.dart              # Quota size, cycle type, reset day, alert %
│   │   │   ├── sim_info_entity.dart               # SubId, carrierName, slotIndex, isDefaultData
│   │   │   ├── speed_sample_entity.dart           # Real-time download/upload B/s snapshot
│   │   │   └── hourly_spike_entity.dart           # Hour index, peak bytes, culprit app
│   │   ├── repositories/                          # Abstract Repository Contracts
│   │   │   ├── i_network_repository.dart          # Contract for querying hardware stats & time buckets
│   │   │   ├── i_plan_repository.dart             # Contract for persisting plan quotas
│   │   │   └── i_settings_repository.dart         # Contract for live speed & interval settings
│   │   └── use_cases/                             # Isolated Business Logic Interactors
│   │       ├── get_today_usage_use_case.dart      # Queries today's mobile & Wi-Fi summary
│   │       ├── get_historical_summary_use_case.dart# Aggregates multi-timeframe trends (Today/Week/Month/Year)
│   │       ├── get_app_breakdown_use_case.dart    # Queries per-app breakdown for selected TimeRange
│   │       ├── get_hourly_spikes_use_case.dart    # Detects 24-hour peak network spikes
│   │       ├── get_active_sim_info_use_case.dart  # Detects current active carrier connection
│   │       ├── get_data_plan_use_case.dart        # Fetches user plan configuration
│   │       ├── save_data_plan_use_case.dart       # Validates and persists new plan quota
│   │       └── toggle_live_speed_use_case.dart    # Starts or halts foreground speed service
│   │
│   ├── data/                                      # Data Access & Persistence Layer
│   │   ├── models/                                # Data Transfer Objects (flutter-implement-json)
│   │   │   ├── app_usage_dto.dart                 # JSON/Map serializer for app usage records
│   │   │   ├── network_summary_dto.dart           # JSON/Map serializer for device summaries
│   │   │   ├── usage_time_bucket_dto.dart         # JSON/Map serializer for discrete time buckets
│   │   │   ├── data_plan_dto.dart                 # Serialization for user plan quotas
│   │   │   ├── sim_info_dto.dart                  # Serialization for SubscriptionManager data
│   │   │   └── speed_sample_dto.dart              # EventChannel live speed snapshot DTO
│   │   ├── services/                              # Stateless External & Platform Wrappers
│   │   │   ├── native_network_service.dart        # MethodChannel & EventChannel implementation
│   │   │   ├── cold_start_backfill_service.dart   # Backfills SQLite from OS kernel logs (zero synthetic data)
│   │   │   ├── local_database_service.dart        # SQLite time-series database manager
│   │   │   └── local_preferences_service.dart     # SharedPreferences key-value wrapper
│   │   ├── database/                              # SQLite Architecture (DAO Pattern)
│   │   │   ├── app_database.dart                  # Database initialization & migrations
│   │   │   ├── database_tables.dart               # Table definitions & indexing DDL
│   │   │   └── daos/
│   │   │       ├── network_snapshots_dao.dart     # DAO for hourly device network snapshots
│   │   │       ├── daily_rollups_dao.dart         # DAO for daily rollups (Weekly & Monthly views)
│   │   │       ├── monthly_rollups_dao.dart       # DAO for monthly rollups (Yearly view)
│   │   │       └── app_usage_dao.dart             # DAO for daily per-app usage records
│   │   └── repositories/                          # Concrete Repository Implementations
│   │       ├── network_repository_impl.dart       # Coordinates NativeService + SQLite Cache
│   │       ├── plan_repository_impl.dart          # Manages DataPlan persistence
│   │       └── settings_repository_impl.dart      # Manages user preferences & service state
│   │
│   └── ui/                                        # Presentation Layer (MVVM Architecture)
│       ├── core/                                  # Shared UI Components & Helpers
│       │   ├── animations/
│       │   │   ├── count_up_text.dart             # Rolling numeric ticker (400ms easeOutCubic)
│       │   │   ├── pulse_indicator.dart           # Dynamic glowing speed pulse halo
│       │   │   └── radial_gauge.dart              # Custom-painted Material 3 circular plan arc
│       │   └── widgets/
│       │       ├── adaptive_scaffold.dart         # Responsive shell (NavigationBar vs Rail)
│       │       ├── time_range_segmented_button.dart# Material 3 Today/Weekly/Monthly/Yearly selector
│       │       ├── metric_card.dart               # Standardized Material 3 card container
│       │       ├── carrier_badge.dart             # Clean chip displaying active carrier
│       │       ├── empty_state_card.dart          # Guidance card when permissions are needed
│       │       ├── error_snackbar.dart            # Transient error notification banner
│       │       └── frosted_container.dart         # Subtle tonal surface overlay
│       │
│       └── features/                              # Feature Modules (ViewModel + View)
│           ├── onboarding/                        # Feature 0: 5-Step Guided Onboarding
│           │   ├── view_models/
│           │   │   └── onboarding_view_model.dart # Onboarding state & permission checker
│           │   ├── views/
│           │   │   └── onboarding_view.dart       # Carousel host widget
│           │   └── widgets/
│           │       └── permission_slide.dart      # Individual permission explanation card
│           │
│           ├── dashboard/                         # Feature 1: Dashboard (Home)
│           │   ├── view_models/
│           │   │   └── dashboard_view_model.dart  # Drives live pulse, plan gauge, daily summary
│           │   ├── views/
│           │   │   └── dashboard_view.dart        # Screen view widget with ListenableBuilder
│           │   └── widgets/
│           │       ├── speed_pulse_card.dart      # Hero dual speedometer (Download / Upload)
│           │       ├── plan_progress_ring.dart    # Visual % consumed gauge & days left
│           │       ├── daily_comparison_tile.dart # Side-by-side Mobile vs Wi-Fi metrics
│           │       └── top_apps_preview_card.dart # Mini ranking of top 3 apps today
│           │
│           ├── app_usage/                         # Feature 2: App Usage Detective
│           │   ├── view_models/
│           │   │   └── app_usage_view_model.dart  # Search debouncing, sorting across Today/Week/Month/Year
│           │   ├── views/
│           │   │   └── app_usage_view.dart        # Virtualized ListView with itemExtent: 76.0
│           │   └── widgets/
│           │       ├── app_usage_tile.dart        # App row (Icon, Name, Bytes, FG/BG pill)
│           │       ├── app_search_filter_bar.dart # Search input + Network & TimeRange chips
│           │       ├── app_details_bottom_sheet.dart # Dynamic app timeline modal sheet
│           │       └── foreground_background_bar.dart # Stacked horizontal FG vs BG meter
│           │
│           ├── history/                           # Feature 3: History & Spikes (Multi-Timeframe)
│           │   ├── view_models/
│           │   │   └── history_view_model.dart    # Aggregates Today (24h), Week (7d), Month (30d), Year (12mo)
│           │   ├── views/
│           │   │   └── history_view.dart          # Host view with TimeRange switcher
│           │   └── widgets/
│           │       ├── hourly_spike_chart.dart    # Interactive fl_chart 24-hr bar canvas for Today
│           │       ├── weekly_comparison_chart.dart # 7-day comparative grouped bars
│           │       ├── monthly_trajectory_chart.dart # 30-day cumulative burn curve vs ideal quota pace
│           │       ├── yearly_distribution_chart.dart # 12-month annual cellular vs Wi-Fi distribution
│           │       ├── spike_culprit_card.dart    # Highlights peak hour/day & primary consumer app
│           │       └── insights_grid.dart         # Average daily, projected total, offload ratio
│           │
│           ├── plan/                              # Feature 4: Plan & Quota Settings
│           │   ├── view_models/
│           │   │   └── plan_view_model.dart       # Quota calculations, daily pace math
│           │   ├── views/
│           │   │   └── plan_view.dart             # Plan configuration view
│           │   └── widgets/
│           │       ├── carrier_status_card.dart   # Informational active carrier card
│           │       ├── plan_summary_card.dart     # Quota used, remaining, daily allowance
│           │       └── edit_plan_modal_sheet.dart # Bottom sheet with quota slider & cycle picker
│           │
│           └── settings/                          # Feature 5: App Settings & Status Bar
│               ├── view_models/
│               │   └── settings_view_model.dart   # Notification switch, interval, units, health
│               ├── views/
│               │   └── settings_view.dart         # Grouped settings view
│               └── widgets/
│                   ├── status_bar_settings_tile.dart # Live speed toggle & 1.0s-3.0s picker
│                   ├── battery_saver_card.dart    # Explains ACTION_SCREEN_OFF sleep pause
│                   ├── permission_health_card.dart# Live status of system permissions
│                   └── privacy_guarantee_tile.dart# 100% on-device sandboxing statement
│
├── test/                                          # Automated Testing Suite (dart-add-unit-test)
│   ├── unit/                                      # Pure Dart Unit Tests
│   │   ├── core/
│   │   │   ├── byte_formatter_test.dart           # B, KB, MB, GB, TB formatting assertions
│   │   │   ├── date_utils_test.dart               # Billing cycle reset date & leap year math
│   │   │   └── result_test.dart                   # Result<Success, Failure> monad branching
│   │   ├── domain/
│   │   │   ├── time_range_test.dart               # Date range calculations for today/week/month/year
│   │   │   ├── historical_summary_entity_test.dart# Multi-timeframe totals and offload % calculations
│   │   │   ├── data_plan_entity_test.dart         # Quota percentage & remaining math
│   │   │   ├── get_today_usage_use_case_test.dart # UseCase business logic validation
│   │   │   └── get_hourly_spikes_use_case_test.dart# Spike detection algorithm test
│   │   └── data/
│   │       ├── app_usage_dto_test.dart            # JSON serialization roundtrip test
│   │       └── network_repository_impl_test.dart  # Cache hit/miss & database fallback test
│   │
│   ├── widget/                                    # Component Widget Tests (flutter-add-widget-test)
│   │   ├── features/
│   │   │   ├── dashboard_view_test.dart           # Tests speedometer & plan gauge rendering
│   │   │   ├── app_usage_view_test.dart           # Tests search filtering & list interaction
│   │   │   ├── history_view_test.dart             # Tests chart tooltip & view switching
│   │   │   └── plan_view_test.dart                # Tests quota edit sheet interactions
│   │   └── core/
│   │       ├── radial_gauge_test.dart             # CustomPainter arc rendering test
│   │       └── speed_pulse_card_test.dart         # Animated pulse widget test
│   │
│   └── mocks/                                     # Mock Dependencies for Testing
│       ├── mock_native_network_service.dart       # Mocked MethodChannel / EventChannel
│       └── mock_repositories.dart                 # Mocked repository interfaces
│
├── docs/                                          # Complete Documentation Suite
│   ├── FULL_PROJECT_TREE_ARCHITECTURE.md          # THIS COMPLETE EXHAUSTIVE SPECIFICATION
│   ├── DETAILED_PHASE_EXECUTION_TRACKER.md        # Step-by-step implementation tracker & gates
│   ├── DYNAMIC_DATA_PIPELINE_AND_TIME_RANGES.md   # Dynamic multi-timeframe spec (Today/Week/Month/Year)
│   ├── PACKAGE_SELECTION_AND_ECOSYSTEM.md         # Flutter package selection & ecosystem ADR
│   ├── PERFORMANCE_OPTIMIZATION_PLAN.md           # 120 FPS & 0% CPU battery optimization plan
│   ├── PRODUCTION_ENGINEERING_PLAN.md             # Senior Clean Architecture & SQLite Blueprint
│   ├── OPEN_SOURCE_BENCHMARKING.md                # DataMonitor, Traffic Light, FlowBytes benchmarks
│   ├── GRAPHIFY_KNOWLEDGE_GRAPH.md                # Graphify AST knowledge graph & visualizer
│   ├── WIFI_USAGE_SPEC.md                         # Dedicated Wi-Fi kernel queries & FUP plans
│   ├── NAVBAR_DESIGN.md                           # Material 3 NavigationBar & NavigationRail ADR
│   ├── ICON_LIBRARY_DECISION.md                   # Material 3 Rounded tree-shaking ADR
│   ├── APP_ARCHITECTURE_AND_SPECS.md              # Screen hierarchy, typography, onboarding specs
│   ├── UI_UX_DESIGN.md                            # Material 3 wireframes & responsive layouts
│   ├── FEATURES.md                                # Exhaustive feature specification
│   ├── ARCHITECTURE.md                            # High-level architecture & privacy model
│   ├── ANDROID_SUBSYSTEM.md                       # Native Kotlin services, stats & widgets
│   ├── FLUTTER_DESIGN.md                          # MVVM state management & Flutter models
│   └── IMPLEMENTATION_ROADMAP.md                  # 4-phase execution checklist & tests
│
├── l10n.yaml                                      # Flutter Localization Configuration
├── pubspec.yaml                                   # Dependencies & project metadata
└── README.md                                      # Project overview & quickstart guide
```

---

## 2. Layer-by-Layer Responsibility Matrix

| Layer | Directory Path | Responsibility & Constraint |
| :--- | :--- | :--- |
| **Presentation (UI)** | `lib/ui/features/[feature]/` | **MVVM Pattern**: Dumb Views (`StatelessWidget`) driven by ViewModels (`ChangeNotifier`) via `ListenableBuilder`. Zero business logic. |
| **Domain** | `lib/domain/` | **100% Pure Dart**: Immutable Entities, abstract Repository interfaces, and UseCase interactors. Zero Flutter or database imports. |
| **Data** | `lib/data/` | **Single Source of Truth**: Concrete Repositories coordinating stateless services (`NativeNetworkService`) and indexed SQLite database (`LocalDatabaseService`). |
| **Core** | `lib/core/` | **Foundational Infrastructure**: Functional `Result<S, F>` monad, typed `AppFailure` hierarchy, `ByteFormatter`, and `AppTheme`. |
| **Android Native** | `android/app/src/main/kotlin/` | **Hardware Accounting & System Services**: `NetworkStatsManager` queries, `TrafficStats` delta engine, `LiveSpeedService`, `ScreenReceiver`, and `ByteFlowWidgetProvider`. |
| **Testing** | `test/` | **Quality Assurance**: Unit tests for UseCases/math, Widget tests for ViewModels/UI, and mock platform channels. |
