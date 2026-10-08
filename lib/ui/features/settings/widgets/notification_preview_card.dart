import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

/// Authentic Samsung One UI (One UI 4–5 / Android 12) Live Notification Preview.
/// Matches the reference screenshots of "Internet Speed Meter Lite" on Samsung Galaxy.
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

  // Colors matching Samsung One UI dark mode notification shade
  static const Color _oneUiNotifBg = Color(0xFF2A2A2A);
  static const Color _oneUiTextPrimary = Color(0xFFFFFFFF);
  static const Color _oneUiTextSecondary = Color(0xFFB0B0B0);
  static const Color _oneUiChevron = Color(0xFF8E8E93);
  static const Color _oneUiBlue = Color(0xFF2C75FF);
  static const Color _oneUiInactiveToggle = Color(0xFF3A3A3C);
  static const Color _oneUiUnitBlue = Color(0xFF7CA8F8);

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
                          'One UI Shade View',
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
                    // One UI Quick Settings Panel
                    _buildQuickSettingsPanel(),
                  ],

                  // Notification Shade Card Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isExpanded
                          ? _buildExpandedCard()
                          : _buildCollapsedCard(),
                    ),
                  ),

                  if (_showShadeContext) ...[
                    // Bottom actions: Notification settings & Clear
                    _buildShadeFooter(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// System Status Bar replicating Samsung One UI 4-5
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
                    color: _oneUiTextSecondary,
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

  /// Collapsed Samsung One UI notification card (No app title)
  Widget _buildCollapsedCard() {
    final dlVal = '0';
    final dlUnit = widget.useBits ? 'Kbps' : 'KB/s';
    final lineSpeeds = widget.useBits
        ? 'Down: 0 b/s   Up: 0 b/s'
        : 'Down: 0 B/s   Up: 0 B/s';
    final lineTraffic = 'Mobile: 910.4 MB   WiFi: 0 MB';

    return Container(
      key: const ValueKey('collapsed_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: _oneUiNotifBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left speed indicator: Numeric value on top, unit underneath
          SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dlVal,
                  style: const TextStyle(
                    color: _oneUiTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  dlUnit,
                  style: const TextStyle(
                    color: _oneUiUnitBlue,
                    fontSize: 9.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Main text lines
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lineSpeeds,
                  style: const TextStyle(
                    color: _oneUiTextPrimary,
                    fontSize: 13.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lineTraffic,
                  style: const TextStyle(
                    color: _oneUiTextSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Subtle downward chevron
          const Icon(
            Icons.keyboard_arrow_down,
            color: _oneUiChevron,
            size: 18,
          ),
        ],
      ),
    );
  }

  /// Expanded Samsung One UI notification card (With app identity header)
  Widget _buildExpandedCard() {
    final dlVal = '0';
    final dlUnit = widget.useBits ? 'Kbps' : 'KB/s';
    final lineSpeeds = widget.useBits
        ? 'Down: 0 b/s   Up: 0 b/s'
        : 'Down: 0 B/s   Up: 0 B/s';
    final lineTraffic = 'Mobile: 910.4 MB   WiFi: 0 MB';

    return Container(
      key: const ValueKey('expanded_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: _oneUiNotifBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left speed indicator: Numeric value on top, unit underneath
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: SizedBox(
              width: 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dlVal,
                    style: const TextStyle(
                      color: _oneUiTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    dlUnit,
                    style: const TextStyle(
                      color: _oneUiUnitBlue,
                      fontSize: 9.5,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Main content: App title, speeds, traffic stats
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: App Name
                const Text(
                  'Internet Speed Meter Lite',
                  style: TextStyle(
                    color: _oneUiTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Line 2: Speeds
                Text(
                  lineSpeeds,
                  style: const TextStyle(
                    color: _oneUiTextPrimary,
                    fontSize: 13.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                // Line 3: Traffic Stats
                Text(
                  lineTraffic,
                  style: const TextStyle(
                    color: _oneUiTextSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Subtle upward chevron
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: _oneUiChevron,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Samsung One UI Quick Settings Panel
  Widget _buildQuickSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Date & Settings Row
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

          // Quick Toggle Circles
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

          // Brightness Slider Mockup
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
        color: isActive ? _oneUiBlue : _oneUiInactiveToggle,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildShadeFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notification settings',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Clear',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
