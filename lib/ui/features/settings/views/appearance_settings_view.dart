import 'package:flutter/material.dart';
import '../view_models/settings_view_model.dart';

/// Sub-screen configuring application theming, Material 3 dynamic color integration,
/// and OLED true dark mode preferences.
class AppearanceSettingsView extends StatelessWidget {
  final SettingsViewModel viewModel;

  const AppearanceSettingsView({
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
        final currentMode = viewModel.themeMode;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Appearance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Theme Mode Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'DISPLAY THEME',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      RadioGroup<ThemeMode>(
                        groupValue: currentMode,
                        onChanged: (mode) {
                          if (mode != null) viewModel.setThemeMode(mode);
                        },
                        child: Column(
                          children: [
                            // System Default Radio Tile
                            RadioListTile<ThemeMode>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('System Default'),
                              subtitle: Text(
                                'Matches your Android system dark mode schedule.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              secondary: const Icon(Icons.brightness_auto_rounded),
                              value: ThemeMode.system,
                            ),
                            const Divider(height: 16),

                            // Light Mode Radio Tile
                            RadioListTile<ThemeMode>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Light Mode'),
                              subtitle: Text(
                                'Clean high-contrast daytime interface.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              secondary: const Icon(Icons.light_mode_rounded),
                              value: ThemeMode.light,
                            ),
                            const Divider(height: 16),

                            // Dark Mode Radio Tile
                            RadioListTile<ThemeMode>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Dark Mode (OLED)'),
                              subtitle: Text(
                                'Pure black surfaces optimized for AMOLED battery saving.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              secondary: const Icon(Icons.dark_mode_rounded),
                              value: ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Material 3 Monet Dynamic Color Card
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
                        Icons.auto_awesome_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dynamic Color Palette',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'On supported Android 12+ devices, ByteFlow automatically extracts and harmonizes Monet accent colors derived from your device wallpaper.',
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
