// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ByteFlow';

  @override
  String get helloMessage => 'ByteFlow Network Monitor';

  @override
  String get appDescription => 'Offline Android Network Monitor & Data Saver';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabApps => 'Apps';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlan => 'Plans';

  @override
  String get tabSettings => 'Settings';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get todayMobile => 'Today Mobile';

  @override
  String get todayWifi => 'Today Wi-Fi';

  @override
  String get searchAppsHint => 'Search applications...';

  @override
  String get filterAll => 'All Networks';

  @override
  String get filterMobile => 'Mobile';

  @override
  String get filterWifi => 'Wi-Fi';

  @override
  String get foreground => 'Foreground';

  @override
  String get background => 'Background';

  @override
  String get timeRangeToday => 'Today';

  @override
  String get timeRangeWeek => 'Weekly';

  @override
  String get timeRangeMonth => 'Monthly';

  @override
  String get timeRangeYear => 'Yearly';

  @override
  String get dailyAverage => 'Daily Average';

  @override
  String get projectedTotal => 'Projected Total';

  @override
  String get wifiOffload => 'Wi-Fi Offload';

  @override
  String get cellularPlan => 'Cellular Plan';

  @override
  String get wifiPlan => 'Wi-Fi Plan';

  @override
  String get quotaUsed => 'Quota Used';

  @override
  String get quotaRemaining => 'Quota Remaining';

  @override
  String daysRemaining(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get exportReport => 'Export Usage Report';

  @override
  String get clearCache => 'Clear Cached History';

  @override
  String get openSourceLicenses => 'Open Source Licenses';
}
