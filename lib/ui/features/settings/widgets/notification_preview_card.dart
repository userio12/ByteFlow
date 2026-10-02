import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';

/// Interactive live simulation of ByteFlow's Android notification speed meter.
/// Allows users to preview Collapsed vs Expanded layouts in real time with active unit preferences.
class NotificationPreviewCard extends StatefulWidget {
  final bool useBits;
  final bool isStatusBarSpeedIcon;
  final bool isLiveSpeedEnabled;

  const NotificationPreviewCard({
    super.key,
    required this.useBits,
    required this.isStatusBarSpeedIcon,
    this.isLiveSpeedEnabled = true,
  });

  @override
  State<NotificationPreviewCard> createState() => _NotificationPreviewCardState();
}

class _NotificationPreviewCardState extends State<NotificationPreviewCard> {
  bool _isExpanded = false;

  // Sample preview throughput rates (14.8 MB/s download, 2.1 MB/s upload)
  static const int _sampleDlBps = 15518924; // ~14.8 MB/s
  static const int _sampleUlBps = 2202009;  // ~2.1 MB/s

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dlFormatted = ByteFormatter.formatSpeed(
      _sampleDlBps,
      useBits: widget.useBits,
    );
    final ulFormatted = ByteFormatter.formatSpeed(
      _sampleUlBps,
      useBits: widget.useBits,
    );
    final statusIconText = widget.useBits ? '118m' : '14M';

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header with Layout Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.dashboardActive,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NOTIFICATION PREVIEW',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Collapsed'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Expanded'),
                    ),
                  ],
                  selected: {_isExpanded},
                  onSelectionChanged: (val) {
                    setState(() {
                      _isExpanded = val.first;
                    });
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Simulated Android System Status Bar Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Text(
                    '10:09',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.isStatusBarSpeedIcon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF06B6D4), width: 0.8),
                      ),
                      child: Text(
                        statusIconText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06B6D4),
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.speed, size: 14, color: Colors.white70),
                  const Spacer(),
                  const Icon(Icons.wifi, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  const Icon(Icons.signal_cellular_alt, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '92%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.battery_full, size: 14, color: Colors.white70),
                ],
              ),
            ),

            // Simulated Notification Body
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _isExpanded
                  ? _buildExpandedPreview(context, dlFormatted, ulFormatted)
                  : _buildCollapsedPreview(context, dlFormatted, ulFormatted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedPreview(
    BuildContext context,
    String dlSpeed,
    String ulSpeed,
  ) {
    return Container(
      key: const ValueKey('collapsed_preview'),
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1C20),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Row(
        children: [
          // Download Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D313A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '↓ ',
                  style: TextStyle(
                    color: Color(0xFF06B6D4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  dlSpeed,
                  style: const TextStyle(
                    color: Color(0xFFF1F3F9),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Upload Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D313A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '↑ ',
                  style: TextStyle(
                    color: Color(0xFFEC4899),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  ulSpeed,
                  style: const TextStyle(
                    color: Color(0xFFF1F3F9),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Today's Total
          const Text(
            'Today: 1.65 GB',
            style: TextStyle(
              color: Color(0xFF9DA3AE),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPreview(
    BuildContext context,
    String dlSpeed,
    String ulSpeed,
  ) {
    return Container(
      key: const ValueKey('expanded_preview'),
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1C20),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'ByteFlow • Speed Monitor',
                style: TextStyle(
                  color: Color(0xFFF1F3F9),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '● Live',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D313A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Wi-Fi 5G',
                  style: TextStyle(
                    color: Color(0xFFF1F3F9),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dual Metric Tiles
          Row(
            children: [
              // Download Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23262D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF353942)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('↓ ', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('DOWNLOAD', style: TextStyle(color: Color(0xFF9DA3AE), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dlSpeed,
                        style: const TextStyle(
                          color: Color(0xFFF1F3F9),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          value: 0.65,
                          minHeight: 3,
                          backgroundColor: Color(0xFF2B2E36),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Upload Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23262D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF353942)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('↑ ', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('UPLOAD', style: TextStyle(color: Color(0xFF9DA3AE), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ulSpeed,
                        style: const TextStyle(
                          color: Color(0xFFF1F3F9),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          value: 0.25,
                          minHeight: 3,
                          backgroundColor: Color(0xFF2B2E36),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Today's Usage Breakdown
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF23262D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF353942)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Usage", style: TextStyle(color: Color(0xFF9DA3AE), fontSize: 10, fontWeight: FontWeight.bold)),
                    Text("60%", style: TextStyle(color: Color(0xFFF1F3F9), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    value: 0.60,
                    minHeight: 3,
                    backgroundColor: Color(0xFF2B2E36),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cellular),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cell: 1.2 GB / 2.0 GB • Wi-Fi: 450 MB',
                  style: TextStyle(color: Color(0xFF9DA3AE), fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Action Buttons Row
          Row(
            children: [
              _buildActionButton('⚡ Dashboard'),
              const SizedBox(width: 6),
              _buildActionButton('📊 Plan'),
              const SizedBox(width: 6),
              _buildActionButton('⏸ Pause'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2D313A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF353942)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF1F3F9),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
