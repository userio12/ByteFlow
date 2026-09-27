import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';

/// A single presentation slide in the onboarding carousel explaining a permission or architecture benefit.
class PermissionSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bulletPoints;
  final bool? isGranted;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final Color? accentColor;

  const PermissionSlide({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.bulletPoints = const [],
    this.isGranted,
    this.buttonLabel,
    this.onButtonPressed,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = accentColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              size: 56,
              color: primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: bulletPoints
                    .map(
                      (bp) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              AppIcons.checkCircle,
                              size: 16,
                              color: AppColors.wifi,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bp,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (isGranted != null || buttonLabel != null) ...[
            const SizedBox(height: 32),
            if (isGranted == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    AppIcons.checkCircle,
                    color: AppColors.wifi,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Permission Granted',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.wifi,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else if (buttonLabel != null && onButtonPressed != null)
              FilledButton.tonal(
                onPressed: onButtonPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(buttonLabel!),
              ),
          ],
        ],
      ),
    );
  }
}
