import 'package:flutter/material.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/battery_saver_card.dart';
import '../widgets/permission_health_card.dart';

/// Sub-screen reviewing ByteFlow's zero-CPU battery preservation architecture,
/// OEM background killer defense, and Android system permissions status.
class SystemHealthSettingsView extends StatelessWidget {
  final SettingsViewModel viewModel;

  const SystemHealthSettingsView({
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
              'Battery & System Health',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Battery Saver Card (ACTION_SCREEN_OFF + OEM Defense)
              BatterySaverCard(
                isBatteryOptimizationsIgnored: viewModel.isBatteryOptimizationsIgnored,
                onRequestExemption: viewModel.requestBatteryOptimizationExemption,
              ),
              const SizedBox(height: 16),

              // 2. System Permissions Health
              PermissionHealthCard(
                hasUsagePermission: viewModel.hasUsagePermission,
                hasPhoneStatePermission: viewModel.hasPhoneStatePermission,
                onOpenUsageSettings: viewModel.openUsageSettings,
              ),
            ],
          ),
        );
      },
    );
  }
}
