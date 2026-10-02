import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/network_summary_entity.dart';
import '../../../core/widgets/metric_card.dart';
import '../../plan/view_models/plan_view_model.dart';

/// Single responsive card displaying cellular or Wi-Fi data traffic consumed today based on selection.
class DailyComparisonTile extends StatelessWidget {
  final NetworkSummaryEntity summary;
  final PlanCategory selectedCategory;
  final ValueChanged<PlanCategory>? onSelectCategory;

  const DailyComparisonTile({
    super.key,
    required this.summary,
    this.selectedCategory = PlanCategory.cellular,
    this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isWifi = selectedCategory == PlanCategory.wifi;
    final total = isWifi ? summary.wifiTotal : summary.mobileTotal;
    final down = ByteFormatter.format(isWifi ? summary.wifiRx : summary.mobileRx);
    final up = ByteFormatter.format(isWifi ? summary.wifiTx : summary.mobileTx);
    final title = isWifi ? 'Wi-Fi' : 'Cellular';
    final icon = isWifi ? AppIcons.wifi : AppIcons.cellular;
    final color = isWifi ? AppColors.wifi : AppColors.cellular;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2.0),
      ),
      child: MetricCard(
        title: title,
        value: ByteFormatter.format(total),
        subtitle: '↓ $down • ↑ $up',
        icon: icon,
        iconColor: color,
        padding: const EdgeInsets.all(16.0),
        onTap: onSelectCategory != null
            ? () => onSelectCategory!(isWifi ? PlanCategory.cellular : PlanCategory.wifi)
            : null,
      ),
    );
  }
}

