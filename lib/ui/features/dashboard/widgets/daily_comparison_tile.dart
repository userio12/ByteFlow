import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/network_summary_entity.dart';
import '../../../core/widgets/metric_card.dart';
import '../../plan/view_models/plan_view_model.dart';

/// Side-by-side comparison tiles for cellular mobile vs Wi-Fi traffic consumed today.
class DailyComparisonTile extends StatelessWidget {
  final NetworkSummaryEntity summary;
  final PlanCategory? selectedCategory;
  final ValueChanged<PlanCategory>? onSelectCategory;

  const DailyComparisonTile({
    super.key,
    required this.summary,
    this.selectedCategory,
    this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final mobileTotal = summary.mobileTotal;
    final mobileDown = ByteFormatter.format(summary.mobileRx);
    final mobileUp = ByteFormatter.format(summary.mobileTx);

    final wifiTotal = summary.wifiTotal;
    final wifiDown = ByteFormatter.format(summary.wifiRx);
    final wifiUp = ByteFormatter.format(summary.wifiTx);

    final isCellularSelected = selectedCategory == PlanCategory.cellular;
    final isWifiSelected = selectedCategory == PlanCategory.wifi;

    return Row(
      children: [
        // Cellular Mobile Tile
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isCellularSelected
                  ? Border.all(color: AppColors.cellular, width: 2.0)
                  : null,
            ),
            child: MetricCard(
              title: 'Cellular',
              value: ByteFormatter.format(mobileTotal),
              subtitle: '↓ $mobileDown • ↑ $mobileUp',
              icon: AppIcons.cellular,
              iconColor: AppColors.cellular,
              padding: const EdgeInsets.all(14.0),
              onTap: onSelectCategory != null
                  ? () => onSelectCategory!(PlanCategory.cellular)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Wi-Fi Tile
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isWifiSelected
                  ? Border.all(color: AppColors.wifi, width: 2.0)
                  : null,
            ),
            child: MetricCard(
              title: 'Wi-Fi',
              value: ByteFormatter.format(wifiTotal),
              subtitle: '↓ $wifiDown • ↑ $wifiUp',
              icon: AppIcons.wifi,
              iconColor: AppColors.wifi,
              padding: const EdgeInsets.all(14.0),
              onTap: onSelectCategory != null
                  ? () => onSelectCategory!(PlanCategory.wifi)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
