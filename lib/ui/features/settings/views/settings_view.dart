import 'package:flutter/material.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/battery_saver_card.dart';
import '../widgets/data_management_card.dart';
import '../widgets/permission_health_card.dart';
import '../widgets/privacy_guarantee_tile.dart';
import '../widgets/status_bar_settings_tile.dart';

/// The Settings view allowing configuration of live speed status bar notifications,
/// reviewing battery preservation architecture, and checking system permissions health.
class SettingsView extends StatefulWidget {
  final SettingsViewModel viewModel;

  const SettingsView({
    super.key,
    required this.viewModel,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Status Bar Live Speed Service Tile
              StatusBarSettingsTile(
                isLiveSpeedEnabled: vm.isLiveSpeedEnabled,
                onToggleLiveSpeed: vm.toggleLiveSpeed,
                samplingIntervalMs: vm.samplingIntervalMs,
                onIntervalChanged: vm.setSamplingInterval,
                isSpeedUnitBits: vm.isSpeedUnitBits,
                onUnitChanged: vm.setSpeedUnitBits,
              ),
              const SizedBox(height: 12),

              // 2. Battery Saver (ACTION_SCREEN_OFF) Explanation & OEM Defense
              BatterySaverCard(
                isBatteryOptimizationsIgnored: vm.isBatteryOptimizationsIgnored,
                onRequestExemption: vm.requestBatteryOptimizationExemption,
              ),
              const SizedBox(height: 12),

              // 3. Permissions Health Card
              PermissionHealthCard(
                hasUsagePermission: vm.hasUsagePermission,
                hasPhoneStatePermission: vm.hasPhoneStatePermission,
                onOpenUsageSettings: vm.openUsageSettings,
              ),
              const SizedBox(height: 12),

              // 4. Data Management & Backup
              DataManagementCard(
                onExportData: vm.exportUsageData,
                onClearCache: vm.clearHistoricalCache,
              ),
              const SizedBox(height: 12),

              // 5. Privacy Guarantee Pledge
              const PrivacyGuaranteeTile(),
              const SizedBox(height: 16),

              // 6. Open Source Licenses & Legal
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: Icon(Icons.description_outlined, color: colorScheme.primary),
                  title: Text(
                    'Open Source Licenses',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Third-party software libraries and notices',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'ByteFlow',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 ByteFlow Authors. Open source under Apache 2.0 / MIT.',
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  'ByteFlow v1.0.0 (Production Build)\nOffline Android Network Monitor & Data Saver',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
