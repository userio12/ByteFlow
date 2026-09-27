import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/models/data_plan_entity.dart';

/// Card summarizing current data plan configuration, cycle reset schedule, and daily allowance budget.
class PlanSummaryCard extends StatelessWidget {
  final DataPlanEntity plan;
  final int usedBytes;
  final VoidCallback? onEdit;

  const PlanSummaryCard({
    super.key,
    required this.plan,
    required this.usedBytes,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final remainingBytes = plan.remainingBytes(usedBytes);
    final now = DateTime.now();
    final (start, end) = AppDateUtils.calculateBillingCycleBounds(now, plan.resetDay);
    final daysLeft = end.difference(now).inDays.clamp(1, 31);
    final dailyAllowance = (remainingBytes / daysLeft).round();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.planActive, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'PLAN QUOTA & BUDGET',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(AppIcons.edit, size: 20),
                    tooltip: 'Edit Plan Quota',
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow(context, 'Total Quota', ByteFormatter.format(plan.quotaBytes)),
            const Divider(height: 16),
            _buildRow(context, 'Cycle Cadence', plan.cycleType.displayName),
            const Divider(height: 16),
            _buildRow(context, 'Reset Day', 'Day ${plan.resetDay} of each month'),
            const Divider(height: 16),
            _buildRow(
              context,
              'Alert Threshold',
              '${plan.alertThresholdPercent.toInt()}% consumed',
            ),
            const SizedBox(height: 16),
            // Daily Allowance Highlight
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statusNormal.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      AppIcons.trafficPulse,
                      color: AppColors.statusNormal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended Daily Allowance',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '~${ByteFormatter.format(dailyAllowance)} / day',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusNormal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
