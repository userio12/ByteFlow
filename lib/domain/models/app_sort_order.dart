/// Sorting criteria for organizing application telemetry lists.
enum AppSortOrder {
  totalUsageDesc,
  backgroundUsageDesc,
  foregroundUsageDesc,
  nameAsc;

  /// User-facing label for sort menus and bottom sheets.
  String get displayName => switch (this) {
        AppSortOrder.totalUsageDesc => 'Highest Usage',
        AppSortOrder.backgroundUsageDesc => 'Background Hogs',
        AppSortOrder.foregroundUsageDesc => 'Foreground Usage',
        AppSortOrder.nameAsc => 'App Name (A-Z)',
      };
}
