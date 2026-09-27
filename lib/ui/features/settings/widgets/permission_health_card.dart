import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';

/// Card inspecting the live operational status of Android system permissions.
class PermissionHealthCard extends StatelessWidget {
  final bool hasUsagePermission;
  final bool hasPhoneStatePermission;
  final VoidCallback onOpenUsageSettings;

  const PermissionHealthCard({
    super.key,
    required this.hasUsagePermission,
    required this.hasPhoneStatePermission,
    required this.onOpenUsageSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.checkCircle, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'SYSTEM PERMISSIONS HEALTH',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildPermissionItem(
              theme,
              title: 'Usage Access (PACKAGE_USAGE_STATS)',
              description: 'Required to read Android kernel network socket tables.',
              isGranted: hasUsagePermission,
              onTap: onOpenUsageSettings,
            ),
            const Divider(height: 16),
            _buildPermissionItem(
              theme,
              title: 'Phone State (READ_PHONE_STATE)',
              description: 'Detects active SIM slots and carrier network identity.',
              isGranted: hasPhoneStatePermission,
              onTap: onOpenUsageSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    ThemeData theme, {
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isGranted ? AppColors.statusNormal : AppColors.statusWarning)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isGranted ? 'Granted' : 'Missing',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isGranted ? AppColors.statusNormal : AppColors.statusWarning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
