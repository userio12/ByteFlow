import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

/// Compact search and filter bar for App Usage screen with integrated filter sheet launcher.
class AppSearchFilterBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onOpenFilterSheet;
  final bool isFiltered;

  const AppSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onOpenFilterSheet,
    this.isFiltered = false,
  });

  @override
  State<AppSearchFilterBar> createState() => _AppSearchFilterBarState();
}

class _AppSearchFilterBarState extends State<AppSearchFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AppSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search app or package...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIcon: const Icon(AppIcons.search, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (widget.onOpenFilterSheet != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onOpenFilterSheet,
              tooltip: 'Filter options',
              icon: Badge(
                isLabelVisible: widget.isFiltered,
                child: Icon(
                  Icons.tune_rounded,
                  color: widget.isFiltered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
