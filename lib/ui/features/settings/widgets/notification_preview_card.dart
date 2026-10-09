import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

/// Modern ByteFlow Material 3 Live Notification Preview.
/// Renders authentic collapsed and expanded cards matching the native Android RemoteViews.
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
  bool _showShadeContext = false;

  // Modern ByteFlow notification tokens (matching colors.xml)
  static const Color _notifCardBg = Color(0xFF23262D);
  static const Color _notifBadgeBg = Color(0xFF1F2228);
  static const Color _notifBorder = Color(0xFF2F333D);
  static const Color _notifTextPrimary = Color(0xFFF1F3F9);
  static const Color _notifTextSecondary = Color(0xFF9DA3AE);
  static const Color _notifDownload = Color(0xFF06B6D4);
  static const Color _notifUpload = Color(0xFFEC4899);
  static const Color _notifUnitBlue = Color(0xFF8AB4F8);

  // Shade context colors
  static const Color _shadeBlue = Color(0xFF2C75FF);
  static const Color _shadeInactiveToggle = Color(0xFF3A3A3C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Preview Header with Layout Toggle & Shade Mode
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
            const SizedBox(height: 8),

            // Toggle for Shade Context
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  key: const ValueKey('shade_context_toggle'),
                  onTap: () {
                    setState(() {
                      _showShadeContext = !_showShadeContext;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showShadeContext ? Icons.visibility : Icons.visibility_outlined,
                          size: 16,
                          color: _showShadeContext ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'System Shade View',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _showShadeContext ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontWeight: _showShadeContext ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Notification Canvas
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  // System Status Bar Strip
                  _buildStatusBarStrip(),

                  if (_showShadeContext) ...[
                    // Quick Settings Panel
                    _buildQuickSettingsPanel(),
                  ],

                  // Notification Shade Card Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isExpanded
                          ? _buildExpandedCard()
                          : _buildCollapsedCard(),
                    ),
                  ),

                  // Bottom notification shade controls
                  _buildShadeFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// System Status Bar replicating Android status bar with speed indicator
  Widget _buildStatusBarStrip() {
    final statusDlSpeed = '0';
    final statusUnit = widget.useBits ? 'Kbps' : 'KB/s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Text(
            '10:14',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (widget.isStatusBarSpeedIcon)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusDlSpeed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  statusUnit,
                  style: const TextStyle(
                    color: _notifUnitBlue,
                    fontSize: 7,
                    fontWeight: FontWeight.normal,
                    height: 1.0,
                  ),
                ),
              ],
            )
          else
            const Icon(Icons.speed, size: 14, color: Colors.white70),
          const Spacer(),
          const Text(
            'Vo) LTE1',
            style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.signal_cellular_alt, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          const Text(
            '91%',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.battery_full, size: 12, color: Colors.white),
        ],
      ),
    );
  }

  /// Collapsed modern notification card (Dual Down/Up pills and Mobile/Wi-Fi row)
  Widget _buildCollapsedCard() {
    final dlSpeedStr = widget.useBits ? '0 b/s' : '0 B/s';
    final ulSpeedStr = widget.useBits ? '0 b/s' : '0 B/s';
    final lineTraffic = 'Mobile: 910.4 MB  •  Wi-Fi: 0 MB';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('collapsed_card'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = true;
          });
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: _notifCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _notifBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Throughput Pills Row (Down and Up)
              Row(
                children: [
                  // Down Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _notifBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _notifBorder),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Down',
                            style: TextStyle(
                              color: _notifDownload,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dlSpeedStr,
                            style: const TextStyle(
                              color: _notifTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Up Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _notifBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _notifBorder),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Up',
                            style: TextStyle(
                              color: _notifUpload,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            ulSpeedStr,
                            style: const TextStyle(
                              color: _notifTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Subtitle
              Text(
                lineTraffic,
                style: const TextStyle(
                  color: _notifTextSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Expanded modern notification card (ByteFlow title, DOWN/UP cards, and Mobile/Wi-Fi row)
  Widget _buildExpandedCard() {
    final dlSpeedStr = widget.useBits ? '0 b/s' : '0 B/s';
    final ulSpeedStr = widget.useBits ? '0 b/s' : '0 B/s';
    final lineTraffic = 'Mobile: 910.4 MB  •  Wi-Fi: 0 MB';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('expanded_card'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = false;
          });
        },
        child: Ink(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: _notifCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _notifBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ByteFlow
              const Text(
                'ByteFlow',
                style: TextStyle(
                  color: _notifTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              // Dual Metric Cards Row
              Row(
                children: [
                  // DOWN Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _notifBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _notifBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DOWN',
                            style: TextStyle(
                              color: _notifDownload,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dlSpeedStr,
                            style: const TextStyle(
                              color: _notifTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // UP Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _notifBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _notifBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UP',
                            style: TextStyle(
                              color: _notifUpload,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ulSpeedStr,
                            style: const TextStyle(
                              color: _notifTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              // Subtitle
              Text(
                lineTraffic,
                style: const TextStyle(
                  color: _notifTextSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// System Quick Settings Panel Simulation
  Widget _buildQuickSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sun, 4 Oct',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.settings, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildToggleCircle(Icons.wifi, false),
              _buildToggleCircle(Icons.volume_up, true),
              _buildToggleCircle(Icons.bluetooth, false),
              _buildToggleCircle(Icons.swap_vert, true),
              _buildToggleCircle(Icons.screen_lock_portrait, false),
              _buildToggleCircle(Icons.airplanemode_active, false),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCircle(IconData icon, bool isActive) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isActive ? _shadeBlue : _shadeInactiveToggle,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildShadeFooter() {
    return const Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Notification settings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 20),
          Text(
            'Clear',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
