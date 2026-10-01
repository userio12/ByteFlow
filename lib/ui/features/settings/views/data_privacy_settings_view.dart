import 'package:flutter/material.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/data_management_card.dart';
import '../widgets/privacy_guarantee_tile.dart';

/// Sub-screen managing data export (CSV format), local SQLite database rollups cache purging,
/// and reviewing ByteFlow's 100% on-device privacy guarantee pledge.
class DataPrivacySettingsView extends StatelessWidget {
  final SettingsViewModel viewModel;

  const DataPrivacySettingsView({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Data & Storage Management',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Data Management & Export/Purge Controls
              DataManagementCard(
                onExportData: (format) => viewModel.exportUsageData(format: format),
                onClearCache: viewModel.clearHistoricalCache,
              ),
              const SizedBox(height: 16),

              // 2. 100% On-Device Privacy Pledge
              const PrivacyGuaranteeTile(),
            ],
          ),
        );
      },
    );
  }
}
