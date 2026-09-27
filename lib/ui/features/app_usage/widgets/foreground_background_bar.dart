import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/byte_formatter.dart';

/// A stacked horizontal progress bar visualizing Foreground vs Background byte distribution.
class ForegroundBackgroundBar extends StatelessWidget {
  final int foregroundBytes;
  final int backgroundBytes;
  final bool showLabels;
  final double height;

  const ForegroundBackgroundBar({
    super.key,
    required this.foregroundBytes,
    required this.backgroundBytes,
    this.showLabels = true,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = foregroundBytes + backgroundBytes;
    final fgRatio = total > 0 ? (foregroundBytes / total).clamp(0.0, 1.0) : 1.0;
    final bgRatio = total > 0 ? (backgroundBytes / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stacked Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                if (fgRatio > 0)
                  Expanded(
                    flex: (fgRatio * 1000).round().clamp(1, 1000),
                    child: Container(color: AppColors.foregroundUsage),
                  ),
                if (bgRatio > 0)
                  Expanded(
                    flex: (bgRatio * 1000).round().clamp(1, 1000),
                    child: Container(color: AppColors.backgroundUsage),
                  ),
              ],
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              _buildLegendDot(AppColors.foregroundUsage),
              const SizedBox(width: 4),
              Text(
                'FG: ${ByteFormatter.format(foregroundBytes, decimals: 1)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              _buildLegendDot(AppColors.backgroundUsage),
              const SizedBox(width: 4),
              Text(
                'BG: ${ByteFormatter.format(backgroundBytes, decimals: 1)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
