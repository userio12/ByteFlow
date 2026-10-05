# Implementation Plan: Samsung One UI Internet Speed Meter Notification Redesign

> **Mode**: Strict Planning Mode  
> **Status**: Awaiting User Verification & Approval  
> **Reference Screenshots**: `Screenshot_20261004-221459_One UI Home.jpg` (Collapsed), `Screenshot_20261004-221506_One UI Home.jpg` (Expanded), `Screenshot_20261004-221514_One UI Home.jpg` (Status Bar)

---

## 1. Goal Description

Redesign ByteFlow's Android ongoing notification and in-app preview card to be a pixel-faithful, authentic replica of the **Samsung One UI (One UI 4–5, Android 12) "Internet Speed Meter Lite"** system notification shown in the reference screenshots.

### Key Objectives
1. **Collapsed Notification**:
   - Exact dark charcoal One UI card (`#292929` to `#303030`, ~26dp corner radius).
   - Left side: Vertically centered live download speed indicator (numeric speed on top, e.g. `23`, smaller `KB/s` underneath).
   - Main content (immediately to the right):
     - Line 1: `Down: 23 KB/s   Up: 438 B/s`
     - Line 2: `Mobile: 393.5 MB   WiFi: 533 MB`
   - Far right: Subtle light-gray downward chevron (`⌄`).
   - **Crucial Rule**: The app title ("Internet Speed Meter Lite" or "ByteFlow") is **STRICTLY HIDDEN** in collapsed mode.
2. **Expanded Notification**:
   - Exact same One UI card background, corner radius, and speed indicator on the left.
   - Header: App title (`Internet Speed Meter Lite`) displayed at the top.
   - Below header:
     - Line 2: `Down: 28 KB/s   Up: 96 B/s`
     - Line 3: `Mobile: 393.7 MB   WiFi: 533 MB`
   - Far right: Subtle light-gray upward chevron (`⌃`).
   - No extra buttons, progress bars, pink/cyan badges, or decorative iconography.
3. **Surrounding One UI Notification Shade Context**:
   - Provide a full One UI notification shade context mode in the Flutter preview card (AMOLED black backdrop, circular quick settings toggles, brightness slider, "Notification settings", and "Clear").
4. **Android Native Stability & Framework Compliance**:
   - Strictly avoid generic `<View>` spacers in RemoteViews to guarantee zero inflation crashes in Android SystemUI.
   - Omit `NotificationCompat.DecoratedCustomViewStyle()` to prevent Android 12 SystemUI from injecting a decorated app header in collapsed mode.
   - Maintain a compliant static drawable (`R.drawable.ic_stat_speed`) for the status bar small icon to prevent Samsung One UI `SemAppIconSolution` crashes.

---

## 2. Visual Architecture & Layout Comparison

```
+--------------------------------------------------------------------------------------------------+
| COLLAPSED STATE (Height: ~64dp, Radius: 26dp, Background: #2A2A2A)                              |
+--------------------------------------------------------------------------------------------------+
|  [ 23 ]   Down: 23 KB/s   Up: 438 B/s                                                       [v]  |
|  [KB/s]   Mobile: 393.5 MB   WiFi: 533 MB                                                        |
+--------------------------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------------------------+
| EXPANDED STATE (Height: ~92dp, Radius: 26dp, Background: #2A2A2A)                               |
+--------------------------------------------------------------------------------------------------+
|  [ 28 ]   Internet Speed Meter Lite                                                         [^]  |
|  [KB/s]   Down: 28 KB/s   Up: 96 B/s                                                             |
|           Mobile: 393.7 MB   WiFi: 533 MB                                                        |
+--------------------------------------------------------------------------------------------------+
```

### Visual Specifications Table

| Element | Collapsed Notification | Expanded Notification | Reference Source |
| :--- | :--- | :--- | :--- |
| **Card Background** | `#2A2A2A` (Charcoal) | `#2A2A2A` (Charcoal) | `Screenshot_20261004-221459_One UI Home.jpg` |
| **Corner Radius** | `26dp` | `26dp` | Samsung One UI 4.x notification standard |
| **App Title** | **Hidden** | `Internet Speed Meter Lite` (~13sp, `#E0E0E0`) | `Screenshot_20261004-221506_One UI Home.jpg` |
| **Left Speed Value** | Live download numeric (e.g. `23`, 17sp bold, `#FFFFFF`) | Live download numeric (e.g. `28`, 17sp bold, `#FFFFFF`) | Reference left column |
| **Left Speed Unit** | `KB/s` (9.5sp, `#B0B0B0`, centered below value) | `KB/s` (9.5sp, `#B0B0B0`, centered below value) | Reference left column |
| **Line 1 (Speeds)** | `Down: 23 KB/s   Up: 438 B/s` (13.5sp) | `Down: 28 KB/s   Up: 96 B/s` (13.5sp) | Reference text |
| **Line 2 (Traffic)** | `Mobile: 393.5 MB   WiFi: 533 MB` (12sp, `#B0B0B0`) | `Mobile: 393.7 MB   WiFi: 533 MB` (12sp, `#B0B0B0`) | Reference text |
| **Right Chevron** | Downward `⌄` (14dp, `#8E8E93`) | Upward `⌃` (14dp, `#8E8E93`) | Reference right edge |
| **Extras (Buttons/Bars)**| None (Strictly minimal) | None (Strictly minimal) | Reference screenshots |

---

## 3. User Review & Decision Points

> [!IMPORTANT]
> **App Title String Alignment**:
> In the expanded notification, the reference displays `Internet Speed Meter Lite`.
> ByteFlow's native string resource can be set to:
> - **Option 1 (Default)**: Show `Internet Speed Meter Lite` in the notification header to 100% replicate the reference screenshot.
> - **Option 2**: Allow a localized or configurable title string (e.g. `ByteFlow` or `Internet Speed Meter Lite` via strings.xml).
> *Proposed*: Add string resource `speed_notification_title` set to `Internet Speed Meter Lite` so it matches the screenshot out-of-the-box, with ability to customize.

> [!NOTE]
> **Chevron Rendering in RemoteViews vs SystemUI**:
> In Android 12 / Samsung One UI 4, when custom RemoteViews are used without `DecoratedCustomViewStyle`:
> We include subtle vector chevrons (`ic_notif_chevron_down.xml` and `ic_notif_chevron_up.xml`) in the layout on the right side. This ensures that in all environments, custom ROMs, and in-app Flutter simulations, the chevron is always pixel-perfect and faithfully placed.

---

## 4. Proposed Changes Grouped by Component

### A. Android Native RemoteViews Layouts & Resources (`android/app/src/main/res/`)

#### 1. `[NEW]` `res/drawable/ic_notif_chevron_down.xml`
- Crisp Samsung-style downward chevron vector (color: `#8E8E93`, size: 14dp x 14dp).

#### 2. `[NEW]` `res/drawable/ic_notif_chevron_up.xml`
- Crisp Samsung-style upward chevron vector (color: `#8E8E93`, size: 14dp x 14dp).

#### 3. `[MODIFY]` `res/drawable/notification_card_background.xml`
- Samsung One UI dark rounded shape: solid `#2A2A2A` with `26dp` corners.

#### 4. `[MODIFY]` `res/values/colors.xml`
- Add One UI notification color constants:
  - `oneui_notif_bg`: `#2A2A2A`
  - `oneui_text_primary`: `#FFFFFF`
  - `oneui_text_secondary`: `#B0B0B0`
  - `oneui_chevron`: `#8E8E93`

#### 5. `[MODIFY]` `res/values/strings.xml`
- Add: `<string name="speed_notification_title">Internet Speed Meter Lite</string>`

#### 6. `[MODIFY]` `res/layout/notification_speed_collapsed.xml`
- **Replaces Material 3 pills with authentic Samsung One UI collapsed card**:
  - Root: `LinearLayout` (horizontal, padding 12dp vertical, 16dp horizontal, background: `@drawable/notification_card_background`).
  - Left: `LinearLayout` (vertical, width: `42dp`, gravity: `center`, `layout_gravity="center_vertical"`):
    - `TextView` (`@+id/notif_speed_val`, textSize: `17sp`, bold, `#FFFFFF`, text: `23`)
    - `TextView` (`@+id/notif_speed_unit`, textSize: `9.5sp`, `#B0B0B0`, text: `KB/s`)
  - Middle: `LinearLayout` (vertical, `layout_weight="1"`, `layout_marginStart="14dp"`, gravity: `center_vertical`):
    - `TextView` (`@+id/notif_line_speeds`, textSize: `13.5sp`, textColor: `#FFFFFF`, text: `Down: 23 KB/s   Up: 438 B/s`)
    - `TextView` (`@+id/notif_line_traffic`, textSize: `12sp`, textColor: `#B0B0B0`, layout_marginTop: `3dp`, text: `Mobile: 393.5 MB   WiFi: 533 MB`)
  - Right: `ImageView` (`@+id/notif_chevron`, src: `@drawable/ic_notif_chevron_down`, `layout_gravity="center_vertical"`, tint: `#8E8E93`).
  - **Zero generic `<View>` tags** (100% RemoteViews safe).

#### 7. `[MODIFY]` `res/layout/notification_speed_expanded.xml`
- **Replaces Material 3 cards/bars/buttons with authentic Samsung One UI expanded card**:
  - Root: `LinearLayout` (horizontal, padding 12dp vertical, 16dp horizontal, background: `@drawable/notification_card_background`).
  - Left: `LinearLayout` (vertical, width: `42dp`, gravity: `center`, `layout_gravity="top|center_horizontal"`, `layout_marginTop="2dp"`):
    - `TextView` (`@+id/notif_expanded_speed_val`, textSize: `17sp`, bold, `#FFFFFF`)
    - `TextView` (`@+id/notif_expanded_speed_unit`, textSize: `9.5sp`, `#B0B0B0`)
  - Middle: `LinearLayout` (vertical, `layout_weight="1"`, `layout_marginStart="14dp"`):
    - `TextView` (`@+id/notif_expanded_title`, text: `@string/speed_notification_title`, textSize: `13.5sp`, textColor: `#FFFFFF`, fontFamily: `sans-serif-medium`)
    - `TextView` (`@+id/notif_expanded_line_speeds`, textSize: `13.5sp`, textColor: `#FFFFFF`, layout_marginTop: `4dp`)
    - `TextView` (`@+id/notif_expanded_line_traffic`, textSize: `12sp`, textColor: `#B0B0B0`, layout_marginTop: `3dp`)
  - Right: `ImageView` (`@+id/notif_expanded_chevron`, src: `@drawable/ic_notif_chevron_up`, `layout_gravity="top"`, layout_marginTop: `2dp`, tint: `#8E8E93`).
  - **Zero generic `<View>` tags**.

---

### B. Android Native Service Layer (`android/app/src/main/kotlin/`)

#### 8. `[MODIFY]` `com/byteflow/service/SpeedNotificationHelper.kt`
- Split speed into numeric value and unit pair (e.g. `23` and `KB/s`, `438` and `B/s`, `1.2` and `MB/s`).
- Populate Collapsed RemoteViews:
  - `setCharSequence(R.id.notif_speed_val, "setText", dlValue)`
  - `setCharSequence(R.id.notif_speed_unit, "setText", dlUnit)`
  - `setCharSequence(R.id.notif_line_speeds, "setText", "Down: $dlStr   Up: $ulStr")`
  - `setCharSequence(R.id.notif_line_traffic, "setText", "Mobile: ${formatBytes(todayMobileBytes)}   WiFi: ${formatBytes(todayWifiBytes)}")`
- Populate Expanded RemoteViews:
  - `setCharSequence(R.id.notif_expanded_speed_val, "setText", dlValue)`
  - `setCharSequence(R.id.notif_expanded_speed_unit, "setText", dlUnit)`
  - `setCharSequence(R.id.notif_expanded_line_speeds, "setText", "Down: $dlStr   Up: $ulStr")`
  - `setCharSequence(R.id.notif_expanded_line_traffic, "setText", "Mobile: ${formatBytes(todayMobileBytes)}   WiFi: ${formatBytes(todayWifiBytes)}")`
- Remove `.setStyle(NotificationCompat.DecoratedCustomViewStyle())` so Android SystemUI does not inject an unwanted app header in collapsed mode.
- Maintain `setSmallIcon(R.drawable.ic_stat_speed)` for status bar stability.

---

### C. Flutter Presentation & Settings Preview (`lib/`)

#### 9. `[MODIFY]` `lib/ui/features/settings/widgets/notification_preview_card.dart`
- Overhaul preview card to accurately replicate the Samsung One UI dark card:
  - Collapsed card: Charcoal background `#2A2A2A`, 26dp radius, speed value `23` on top, `KB/s` underneath, text `Down: 23 KB/s   Up: 438 B/s`, `Mobile: 393.5 MB   WiFi: 533 MB`, downward chevron. No app title.
  - Expanded card: Header `Internet Speed Meter Lite`, text `Down: 28 KB/s   Up: 96 B/s`, `Mobile: 393.7 MB   WiFi: 533 MB`, upward chevron.
  - Add optional **"One UI Shade Context" toggle**:
    - When switched ON, renders the surrounding Samsung One UI quick settings panel:
      - Black backdrop `#000000`
      - Date/Time header: `Sun, 4 Oct` and gear icon
      - Circular quick toggle buttons (Wi-Fi, Sound, Bluetooth, Mobile data, Lock, Airplane mode) with blue `#2C75FF` active state
      - Brightness slider
      - The notification card positioned directly in the shade
      - "Notification settings" and "Clear" text footer underneath
- Remove obsolete Material 3 bars, pink/cyan badges, and dashboard/pause buttons.

#### 10. `[MODIFY]` `lib/ui/features/settings/views/live_speed_settings_view.dart`
- Update view typography and layout to complement the Samsung One UI notification design.

---

### D. Test Suites (`test/`)

#### 11. `[MODIFY]` `test/widget/features/notification_preview_card_test.dart`
- Update widget test expectations:
  - Test Collapsed state: verifies `23`, `KB/s`, `Down: 23 KB/s   Up: 438 B/s`, `Mobile: 393.5 MB   WiFi: 533 MB`, chevron present, app title absent.
  - Test Expanded state: verifies `Internet Speed Meter Lite` header, `Down: 28 KB/s   Up: 96 B/s`, `Mobile: 393.7 MB   WiFi: 533 MB`, upward chevron.
  - Test unit formatting (Bytes vs Bits).
  - All 149 Flutter tests continue to pass with 0 failures.

---

## 5. Verification Plan

### Automated Verification
```bash
# 1. Run all Flutter unit and widget tests
flutter test

# 2. Check for lint or static analysis issues
flutter analyze

# 3. Verify Android native Kotlin build
bash gradlew compileDebugKotlin
```

### Manual Verification on Samsung Galaxy Device
1. **Collapsed Notification**:
   - Swipe down notification shade -> verify notification card is charcoal gray `#2A2A2A` with ~26dp corner radius.
   - Verify speed indicator on the left has numeric speed on top and `KB/s` below it.
   - Verify line 1 is `Down: ...   Up: ...` and line 2 is `Mobile: ...   WiFi: ...`.
   - Verify app name is NOT shown in collapsed view.
   - Verify subtle downward chevron on the right.
2. **Expanded Notification**:
   - Tap or swipe down on the card -> verify it smoothly expands to show `Internet Speed Meter Lite` at the top.
   - Verify lines below show the live speeds and traffic stats.
   - Verify upward chevron on the right.
3. **In-App Flutter Preview**:
   - Open Settings -> Live Speed Settings -> verify the interactive Samsung One UI notification preview card.
