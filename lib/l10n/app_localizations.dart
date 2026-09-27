import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the ByteFlow application
  ///
  /// In en, this message translates to:
  /// **'ByteFlow'**
  String get appTitle;

  /// Greeting message on splash/header
  ///
  /// In en, this message translates to:
  /// **'ByteFlow Network Monitor'**
  String get helloMessage;

  /// Short application description
  ///
  /// In en, this message translates to:
  /// **'Offline Android Network Monitor & Data Saver'**
  String get appDescription;

  /// Dashboard tab label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// Apps detective tab label
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get tabApps;

  /// History analytics tab label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// Data plan tab label
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get tabPlan;

  /// Settings navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Download throughput label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Upload throughput label
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Today's cellular data consumption label
  ///
  /// In en, this message translates to:
  /// **'Today Mobile'**
  String get todayMobile;

  /// Today's Wi-Fi data consumption label
  ///
  /// In en, this message translates to:
  /// **'Today Wi-Fi'**
  String get todayWifi;

  /// Search input placeholder in App Usage screen
  ///
  /// In en, this message translates to:
  /// **'Search applications...'**
  String get searchAppsHint;

  /// Filter button for all network traffic
  ///
  /// In en, this message translates to:
  /// **'All Networks'**
  String get filterAll;

  /// Filter button for cellular traffic
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get filterMobile;

  /// Filter button for Wi-Fi traffic
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get filterWifi;

  /// Foreground data consumption badge
  ///
  /// In en, this message translates to:
  /// **'Foreground'**
  String get foreground;

  /// Background data consumption badge
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// Today 24h time range selector
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeRangeToday;

  /// 7-day time range selector
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get timeRangeWeek;

  /// Billing cycle time range selector
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get timeRangeMonth;

  /// 12-month time range selector
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get timeRangeYear;

  /// Daily average consumption metric label
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get dailyAverage;

  /// Projected end-of-cycle total metric label
  ///
  /// In en, this message translates to:
  /// **'Projected Total'**
  String get projectedTotal;

  /// Wi-Fi offload percentage metric label
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Offload'**
  String get wifiOffload;

  /// Cellular plan tab label
  ///
  /// In en, this message translates to:
  /// **'Cellular Plan'**
  String get cellularPlan;

  /// Wi-Fi / Hotspot plan tab label
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Plan'**
  String get wifiPlan;

  /// Plan quota consumed amount label
  ///
  /// In en, this message translates to:
  /// **'Quota Used'**
  String get quotaUsed;

  /// Plan quota remaining amount label
  ///
  /// In en, this message translates to:
  /// **'Quota Remaining'**
  String get quotaRemaining;

  /// Days remaining in billing cycle
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String daysRemaining(num count);

  /// Export data button in Settings
  ///
  /// In en, this message translates to:
  /// **'Export Usage Report'**
  String get exportReport;

  /// Clear database cache button in Settings
  ///
  /// In en, this message translates to:
  /// **'Clear Cached History'**
  String get clearCache;

  /// Open source licenses settings tile
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
