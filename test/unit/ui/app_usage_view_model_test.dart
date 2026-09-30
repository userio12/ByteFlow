import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/constants/channel_constants.dart';
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
        isSystemApp: false,
      ),
      const AppUsageEntity(
        uid: 10101,
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        rxBytes: 30000000,
        txBytes: 5000000,
        isSystemApp: false,
      ),
      const AppUsageEntity(
        uid: 1000,
        packageName: 'android.uid.system',
        appName: 'Android System',
        rxBytes: 15000000,
        txBytes: 2000000,
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
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.filteredApps, isEmpty);
      expect(viewModel.isLoading, isFalse);
    });

    test('loadApps filters to user installed apps by default', () async {
      await viewModel.loadApps();

      expect(viewModel.filteredApps.length, equals(2));
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
