/// Filter resolutions for isolating user-installed applications from core OS & OEM system services.
enum AppTypeFilter {
  userInstalled,
  system,
  all;

  /// User-facing display title for chips and menus.
  String get displayName => switch (this) {
        AppTypeFilter.userInstalled => 'User Apps',
        AppTypeFilter.system => 'System Services',
        AppTypeFilter.all => 'All Apps',
      };
}
