import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/domain/models/app_sort_order.dart';
import 'package:byteflow/domain/models/app_type_filter.dart';
import 'package:byteflow/domain/models/app_usage_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/use_cases/get_app_breakdown_use_case.dart';
import 'package:byteflow/ui/features/app_usage/view_models/app_usage_view_model.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('AppUsageViewModel Unit Tests', () {
    late FakeNetworkRepository fakeRepo;
    late AppUsageViewModel viewModel;

    final mockApps = [
      const AppUsageEntity(
        uid: 10100,
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        rxBytes: 50000000,
        txBytes: 10000000,
        foregroundRx: 10000000,
        foregroundTx: 5000000,
        backgroundRx: 40000000,
        backgroundTx: 5000000,
        isSystemApp: false,
      ),
      const AppUsageEntity(
        uid: 10101,
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        rxBytes: 30000000,
        txBytes: 5000000,
        foregroundRx: 28000000,
        foregroundTx: 4000000,
        backgroundRx: 2000000,
        backgroundTx: 1000000,
        isSystemApp: false,
      ),
      const AppUsageEntity(
        uid: 1000,
        packageName: 'android.uid.system',
        appName: 'Android System',
        rxBytes: 15000000,
        txBytes: 2000000,
        foregroundRx: 0,
        foregroundTx: 0,
        backgroundRx: 15000000,
        backgroundTx: 2000000,
        isSystemApp: true,
      ),
    ];

    setUp(() {
      fakeRepo = FakeNetworkRepository();
      fakeRepo.appsUsage = mockApps;
      viewModel = AppUsageViewModel(
        getAppBreakdownUseCase: GetAppBreakdownUseCase(fakeRepo),
      );
    });

    test('initial state has correct defaults', () {
      expect(viewModel.selectedRange, equals(TimeRange.today));
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeAll));
      expect(viewModel.selectedAppType, equals(AppTypeFilter.userInstalled));
      expect(viewModel.sortOrder, equals(AppSortOrder.totalUsageDesc));
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.filteredApps, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isFiltered, isFalse);
    });

    test('loadApps filters to user installed apps by default', () async {
      await viewModel.loadApps();

      expect(viewModel.filteredApps.length, equals(2));
      expect(viewModel.totalAppsCount, equals(3));
      expect(viewModel.filteredApps.any((app) => app.packageName == 'com.whatsapp'), isTrue);
      expect(viewModel.filteredApps.any((app) => app.packageName == 'com.spotify.music'), isTrue);
      expect(viewModel.filteredApps.any((app) => app.isSystemApp), isFalse);
      expect(viewModel.totalFilteredBytes, equals(60000000 + 35000000));
    });

    test('setAppType to system shows only system apps', () async {
      await viewModel.loadApps();

      viewModel.setAppType(AppTypeFilter.system);

      expect(viewModel.selectedAppType, equals(AppTypeFilter.system));
      expect(viewModel.filteredApps.length, equals(1));
      expect(viewModel.filteredApps.first.packageName, equals('android.uid.system'));
      expect(viewModel.filteredApps.first.isSystemApp, isTrue);
      expect(viewModel.totalFilteredBytes, equals(17000000));
      expect(viewModel.isFiltered, isTrue);
    });

    test('setAppType to all shows both user and system apps', () async {
      await viewModel.loadApps();

      viewModel.setAppType(AppTypeFilter.all);

      expect(viewModel.selectedAppType, equals(AppTypeFilter.all));
      expect(viewModel.filteredApps.length, equals(3));
      expect(viewModel.totalFilteredBytes, equals(60000000 + 35000000 + 17000000));
    });

    test('switching back to userInstalled filters out system apps again', () async {
      await viewModel.loadApps();

      viewModel.setAppType(AppTypeFilter.all);
      expect(viewModel.filteredApps.length, equals(3));

      viewModel.setAppType(AppTypeFilter.userInstalled);
      expect(viewModel.filteredApps.length, equals(2));
      expect(viewModel.filteredApps.every((a) => !a.isSystemApp), isTrue);
    });

    test('search query filters apps within selected app type', () async {
      await viewModel.loadApps();

      viewModel.setSearchQuery('Spotify');
      expect(viewModel.filteredApps.length, equals(1));
      expect(viewModel.filteredApps.first.appName, equals('Spotify'));

      // Searching for system app while userInstalled is selected returns nothing
      viewModel.setSearchQuery('Android System');
      expect(viewModel.filteredApps, isEmpty);

      // Switching to system finds it
      viewModel.setAppType(AppTypeFilter.system);
      expect(viewModel.filteredApps.length, equals(1));
      expect(viewModel.filteredApps.first.appName, equals('Android System'));
    });

    test('sorting dimensions re-order the filtered apps list', () async {
      await viewModel.loadApps();

      // Total usage descending (default): WhatsApp (60MB) > Spotify (35MB)
      viewModel.setSortOrder(AppSortOrder.totalUsageDesc);
      expect(viewModel.filteredApps.first.appName, equals('WhatsApp'));
      expect(viewModel.filteredApps.last.appName, equals('Spotify'));

      // Background usage descending: WhatsApp (45MB) > Spotify (3MB)
      viewModel.setSortOrder(AppSortOrder.backgroundUsageDesc);
      expect(viewModel.filteredApps.first.appName, equals('WhatsApp'));
      expect(viewModel.filteredApps.last.appName, equals('Spotify'));

      // Foreground usage descending: Spotify (32MB) > WhatsApp (15MB)
      viewModel.setSortOrder(AppSortOrder.foregroundUsageDesc);
      expect(viewModel.filteredApps.first.appName, equals('Spotify'));
      expect(viewModel.filteredApps.last.appName, equals('WhatsApp'));

      // Name ascending: Spotify < WhatsApp
      viewModel.setSortOrder(AppSortOrder.nameAsc);
      expect(viewModel.filteredApps.first.appName, equals('Spotify'));
      expect(viewModel.filteredApps.last.appName, equals('WhatsApp'));
    });

    test('resetFilters restores default filter and sort state', () async {
      await viewModel.loadApps();

      viewModel.setSearchQuery('WhatsApp');
      viewModel.setAppType(AppTypeFilter.all);
      viewModel.setSortOrder(AppSortOrder.nameAsc);
      expect(viewModel.isFiltered, isTrue);

      await viewModel.resetFilters();

      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.selectedAppType, equals(AppTypeFilter.userInstalled));
      expect(viewModel.sortOrder, equals(AppSortOrder.totalUsageDesc));
      expect(viewModel.selectedRange, equals(TimeRange.today));
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeAll));
      expect(viewModel.isFiltered, isFalse);
      expect(viewModel.filteredApps.length, equals(2));
    });

    test('setTimeRange triggers reload with updated range', () async {
      await viewModel.setTimeRange(TimeRange.week);
      expect(viewModel.selectedRange, equals(TimeRange.week));

      await viewModel.setTimeRange(TimeRange.month);
      expect(viewModel.selectedRange, equals(TimeRange.month));

      await viewModel.setTimeRange(TimeRange.year);
      expect(viewModel.selectedRange, equals(TimeRange.year));
    });

    test('setNetworkType triggers reload with updated network mode', () async {
      await viewModel.setNetworkType(ChannelConstants.networkTypeMobile);
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeMobile));

      await viewModel.setNetworkType(ChannelConstants.networkTypeWifi);
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeWifi));

      await viewModel.setNetworkType(ChannelConstants.networkTypeAll);
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeAll));
    });
  });
}
