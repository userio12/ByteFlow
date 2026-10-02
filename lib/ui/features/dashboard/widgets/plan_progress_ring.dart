import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/models/data_plan_entity.dart';
import '../../../core/animations/radial_gauge.dart';
import '../../plan/view_models/plan_view_model.dart';

/// Widget displaying data plan progress ring, consumed/remaining quota, days left, and budget pace.
class PlanProgressRing extends StatelessWidget {
  final DataPlanEntity plan;
  final int usedMobileBytes;
  final PlanCategory category;

  const PlanProgressRing({
    super.key,
    required this.plan,
    required this.usedMobileBytes,
    this.category = PlanCategory.cellular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWifi = category == PlanCategory.wifi;
    final categoryLabel = isWifi ? 'WI-FI' : 'CELLULAR';
    final categoryIcon = isWifi ? AppIcons.wifi : AppIcons.planActive;
    final categoryColor = isWifi ? AppColors.wifi : colorScheme.primary;

    final percent = plan.usagePercent(usedMobileBytes) / 100.0;
    final remainingBytes = plan.remainingBytes(usedMobileBytes);
    final isWarning = plan.isWarning(usedMobileBytes);
    final isAlert = plan.isAlert(usedMobileBytes);

    // Calculate days left in cycle
    final now = DateTime.now();
    final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, plan.resetDay);
    final daysLeft = end.difference(now).inDays.clamp(0, 31);

    final (paceText, paceColor) = switch ((isAlert, isWarning)) {
      (true, _) => ('Exceeded', AppColors.statusCritical),
      (false, true) => ('Near Limit', AppColors.statusWarning),
      _ => ('On Track', AppColors.statusNormal),
    };

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              children: [
                Icon(categoryIcon, size: 18, color: categoryColor),
                const SizedBox(width: 8),
                Text(
                  '${plan.cycleType.displayName.toUpperCase()} $categoryLabel PLAN',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gauge & Breakdown Row
            Row(
              children: [
                // Gauge
                SizedBox(
                  width: 130,
                  height: 130,
                  child: RadialGauge(
                    percent: percent,
                    size: 130,
                    strokeWidth: 12,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(percent * 100).toInt()}%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'USED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Metrics List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricRow(
                        context,
                        'Used',
                        ByteFormatter.format(usedMobileBytes),
                        isEmphasized: true,
                      ),
                      const SizedBox(height: 4),
                      _buildMetricRow(
                        context,
                        'Remaining',
                        ByteFormatter.format(remainingBytes),
                      ),
                      const SizedBox(height: 4),
                      _buildMetricRow(
                        context,
                        'Total Quota',
                        ByteFormatter.format(plan.quotaBytes),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: paceColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: paceColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  paceText,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: paceColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$daysLeft days left',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value, {
    bool isEmphasized = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
