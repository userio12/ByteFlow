import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';

/// A Material 3 chip displaying carrier network info and active SIM badge.
class CarrierBadge extends StatelessWidget {
  final String carrierName;
  final int slotIndex;
  final bool isDefaultData;
  final bool isRoaming;
  final VoidCallback? onTap;

  const CarrierBadge({
    super.key,
    required this.carrierName,
    this.slotIndex = 0,
    this.isDefaultData = true,
    this.isRoaming = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayName = carrierName.trim().isNotEmpty ? carrierName : 'No SIM';
    final slotLabel = 'SIM ${slotIndex + 1}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.cellular,
              size: 14,
              color: AppColors.cellular,
            ),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '• $slotLabel',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isRoaming) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.statusWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'R',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusWarning,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
