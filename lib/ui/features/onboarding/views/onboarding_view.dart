import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../view_models/onboarding_view_model.dart';
import '../widgets/permission_slide.dart';

/// The 5-step guided onboarding carousel introducing ByteFlow's zero-static architecture
/// and guiding the user through required Android permissions.
class OnboardingView extends StatefulWidget {
  final OnboardingViewModel viewModel;
  final VoidCallback onFinished;

  const OnboardingView({
    super.key,
    required this.viewModel,
    required this.onFinished,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Top App Bar with Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (vm.currentIndex > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => _goToPage(vm.currentIndex - 1),
                        )
                      else
                        const SizedBox(width: 48),
                      Text(
                        'Step ${vm.currentIndex + 1} of 5',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await vm.completeOnboarding();
                          widget.onFinished();
                        },
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),

                // Carousel Slides
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) => vm.setPage(page),
                    children: [
                      // Slide 1: Welcome
                      const PermissionSlide(
                        icon: AppIcons.trafficPulse,
                        title: 'Welcome to ByteFlow',
                        description:
                            'Your intelligent offline Android network monitor and data quota manager.',
                        bulletPoints: [
                          'Real-time status bar download & upload speeds.',
                          'Zero-static data: 100% live hardware accounting.',
                          'Granular Foreground vs Background app detective.',
                        ],
                        accentColor: AppColors.cellular,
                      ),

                      // Slide 2: Privacy Guarantee
                      const PermissionSlide(
                        icon: AppIcons.privacyShield,
                        title: '100% On-Device & Private',
                        description:
                            'ByteFlow operates strictly within your local device sandbox. No remote servers, no tracking.',
                        bulletPoints: [
                          'No remote network traffic or analytics SDKs.',
                          'All database snapshots encrypted and stored locally.',
                          'Zero battery drain with screen-off auto-pause.',
                        ],
                        accentColor: AppColors.wifi,
                      ),

                      // Slide 3: Usage Access
                      PermissionSlide(
                        icon: AppIcons.appsActive,
                        title: 'Usage Access Permission',
                        description:
                            'Android requires Usage Access to read hardware kernel accounting tables for individual apps.',
                        bulletPoints: [
                          'Read mobile and Wi-Fi data per application.',
                          'Detect unusual background data spikes.',
                        ],
                        isGranted: vm.hasUsagePermission,
                        buttonLabel: 'Grant Usage Access',
                        onButtonPressed: () => vm.requestUsagePermission(),
                        accentColor: AppColors.hotspot,
                      ),

                      // Slide 4: Phone State & Notification
                      PermissionSlide(
                        icon: AppIcons.simCard,
                        title: 'SIM & Notification Access',
                        description:
                            'Enables carrier identification, multi-SIM data monitoring, and the live status bar speed meter.',
                        bulletPoints: [
                          'Auto-detect Jio, Airtel, Vi, and global carriers.',
                          'Show ongoing throughput rate in status bar shade.',
                        ],
                        isGranted: vm.hasPhoneStatePermission,
                        accentColor: AppColors.downloadRate,
                      ),

                      // Slide 5: Ready to Flow
                      const PermissionSlide(
                        icon: AppIcons.checkCircle,
                        title: "You're Ready to Flow!",
                        description:
                            'ByteFlow will now backfill recorded kernel statistics and begin real-time monitoring.',
                        bulletPoints: [
                          'Configure monthly data quota at any time in Plan tab.',
                          'Toggle status bar speed meter in Settings.',
                        ],
                        accentColor: AppColors.wifi,
                      ),
                    ],
                  ),
                ),

                // Bottom Pagination Dots & Next / Finish Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicator dots
                      Row(
                        children: List.generate(5, (index) {
                          final isSelected = index == vm.currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: isSelected ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          );
                        }),
                      ),

                      // Next / Complete Button
                      if (vm.currentIndex < 4)
                        FilledButton(
                          onPressed: () => _goToPage(vm.currentIndex + 1),
                          child: const Text('Next'),
                        )
                      else
                        FilledButton(
                          onPressed: () async {
                            await vm.completeOnboarding();
                            widget.onFinished();
                          },
                          child: const Text('Get Started'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
