import 'package:flutter/material.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/notification_preview_card.dart';
import '../widgets/status_bar_settings_tile.dart';

/// Sub-screen configuring the Android status bar foreground live speed service,
/// sampling frequency, and throughput measurement units.
class LiveSpeedSettingsView extends StatelessWidget {
  final SettingsViewModel viewModel;

  const LiveSpeedSettingsView({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Live Speed & Monitoring',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // Interactive Live Notification Preview
              NotificationPreviewCard(
                useBits: viewModel.isSpeedUnitBits,
                isStatusBarSpeedIcon: viewModel.isStatusBarSpeedIcon,
                isLiveSpeedEnabled: viewModel.isLiveSpeedEnabled,
              ),
              const SizedBox(height: 16),

              // Main Speed Configuration Card
              StatusBarSettingsTile(
                isLiveSpeedEnabled: viewModel.isLiveSpeedEnabled,
                onToggleLiveSpeed: viewModel.toggleLiveSpeed,
                samplingIntervalMs: viewModel.samplingIntervalMs,
                onIntervalChanged: viewModel.setSamplingInterval,
                isSpeedUnitBits: viewModel.isSpeedUnitBits,
                onUnitChanged: viewModel.setSpeedUnitBits,
                isStatusBarSpeedIcon: viewModel.isStatusBarSpeedIcon,
                onStatusBarIconChanged: viewModel.setStatusBarSpeedIcon,
              ),
              const SizedBox(height: 16),

              // Architectural Guidance Note
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Bar Persistent Notification',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Android system rules require a foreground service notification to guarantee accurate real-time network delta sampling without background throttling.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
