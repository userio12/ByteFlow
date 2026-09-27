import 'package:flutter/material.dart';

/// Centralized Material 3 rounded icon registry for ByteFlow.
abstract final class AppIcons {
  // Navigation Bar & Tabs
  static const IconData dashboardActive = Icons.speed_rounded;
  static const IconData dashboardInactive = Icons.speed_outlined;
  static const IconData appsActive = Icons.apps_rounded;
  static const IconData appsInactive = Icons.apps_outlined;
  static const IconData historyActive = Icons.insights_rounded;
  static const IconData historyInactive = Icons.insights_outlined;
  static const IconData planActive = Icons.pie_chart_rounded;
  static const IconData planInactive = Icons.pie_chart_outline_rounded;

  // Network Interfaces & Telephony
  static const IconData cellular = Icons.signal_cellular_alt_rounded;
  static const IconData wifi = Icons.wifi_rounded;
  static const IconData hotspot = Icons.wifi_tethering_rounded;
  static const IconData simCard = Icons.sim_card_rounded;
  static const IconData esim = Icons.sim_card_download_rounded;

  // Real-Time Traffic & Throughput
  static const IconData download = Icons.arrow_downward_rounded;
  static const IconData upload = Icons.arrow_upward_rounded;
  static const IconData trafficPulse = Icons.swap_vert_rounded;

  // Status, Security & Diagnostics
  static const IconData batterySaver = Icons.battery_saver_rounded;
  static const IconData privacyShield = Icons.shield_rounded;
  static const IconData alertWarning = Icons.warning_amber_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData errorCircle = Icons.error_outline_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData openInNew = Icons.open_in_new_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
}
