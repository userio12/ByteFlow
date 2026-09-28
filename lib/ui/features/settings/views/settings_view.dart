import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../view_models/settings_view_model.dart';
import 'about_settings_view.dart';
import 'appearance_settings_view.dart';
import 'data_privacy_settings_view.dart';
import 'live_speed_settings_view.dart';
import 'system_health_settings_view.dart';

/// The root Settings hub organizing ByteFlow into 5 modular nested sub-screens:
/// 1. Live Speed & Monitoring
/// 2. Battery & System Health
/// 3. Data & Storage Management
/// 4. Appearance
/// 5. About ByteFlow
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

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        // Subtitle dynamic statuses
        final liveSpeedStatus = vm.isLiveSpeedEnabled
            ? 'Active · ${(vm.samplingIntervalMs / 1000).toStringAsFixed(1)}s'
            : 'Disabled';

        final batteryStatus = vm.isBatteryOptimizationsIgnored
            ? 'Whitelisted · Active'
            : 'Optimized · Tap to review';

        final themeStatus = switch (vm.themeMode) {
          ThemeMode.system => 'System Default',
          ThemeMode.light => 'Light Mode',
          ThemeMode.dark => 'Dark Mode (OLED)',
        };

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
              // Group 1: Network & Monitoring
              _buildSectionHeader(theme, 'NETWORK & SYSTEM'),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: AppIcons.trafficPulse,
                      iconColor: colorScheme.primary,
                      title: 'Live Speed & Monitoring',
                      subtitle: liveSpeedStatus,
                      onTap: () => _navigateTo(
                        LiveSpeedSettingsView(viewModel: vm),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      context,
                      icon: Icons.battery_saver_rounded,
                      iconColor: colorScheme.primary,
                      title: 'Battery & System Health',
                      subtitle: batteryStatus,
                      onTap: () => _navigateTo(
                        SystemHealthSettingsView(viewModel: vm),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Group 2: Preferences & Storage
              _buildSectionHeader(theme, 'PREFERENCES & DATA'),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      iconColor: colorScheme.secondary,
                      title: 'Appearance',
                      subtitle: themeStatus,
                      onTap: () => _navigateTo(
                        AppearanceSettingsView(viewModel: vm),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      context,
                      icon: Icons.storage_rounded,
                      iconColor: colorScheme.secondary,
                      title: 'Data & Storage Management',
                      subtitle: 'CSV export, SQLite cache & privacy pledge',
                      onTap: () => _navigateTo(
                        DataPrivacySettingsView(viewModel: vm),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Group 3: Information & Legal
              _buildSectionHeader(theme, 'ABOUT'),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: _buildSettingsTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  iconColor: colorScheme.tertiary,
                  title: 'About ByteFlow',
                  subtitle: 'v1.0.0 · Architecture & open-source licenses',
                  onTap: () => _navigateTo(
                    const AboutSettingsView(),
                  ),
                ),
              ),
              const SizedBox(height: 32),

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

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      onTap: onTap,
    );
  }
}
