import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/core/utils/color_utils.dart';
import '../../community/screens/community_screen.dart';
import '../../my_activities/screens/activity_list_screen.dart';
import '../../new_activity/screens/new_activity_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../view_model/home_view_model.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.watch(homeViewModelProvider.notifier);
    final currentIndex = state.currentIndex;

    final tabs = [
      const NewActivityScreen(),
      ActivityListScreen(),
      CommunityScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: tabs[currentIndex]),
      bottomNavigationBar: _FloatingPillBottomNav(
        currentIndex: currentIndex,
        onChanged: homeViewModel.setCurrentIndex,
        items: [
          _NavItem(
            icon: Icons.flash_on,
            label: AppLocalizations.of(context)!.start_activity,
          ),
          _NavItem(
            icon: Icons.list,
            label: AppLocalizations.of(context)!.list,
          ),
          _NavItem(
            icon: Icons.people,
            label: AppLocalizations.of(context)!.community,
          ),
          _NavItem(
            icon: Icons.settings,
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _FloatingPillBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<_NavItem> items;

  const _FloatingPillBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = ColorUtils.mainMedium; // màu xanh active
    const inactiveColor = Color(0xFFBDBDBD);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: SizedBox(
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Pill background
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: Offset(0, 8),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (i) {
                      final isActive = i == currentIndex;
                      final item = items[i];

                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onChanged(i),
                          child: SizedBox(
                            height: 64,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // chừa chỗ cho nút nổi (tab active)
                                const SizedBox(height: 2),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: isActive ? 0.0 : 1.0,
                                  child: Icon(item.icon, color: inactiveColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Floating active circle button
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                bottom: 28, // nâng lên khỏi pill
                left: _calcLeft(context, currentIndex, items.length),
                child: _ActiveBubble(
                  icon: items[currentIndex].icon,
                  color: activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calcLeft(BuildContext context, int index, int length) {
    // Tính vị trí tâm theo chiều ngang để đặt bubble đúng tab
    final width = MediaQuery.of(context).size.width;
    // padding trái/phải của widget ngoài: 18, và container dùng Expanded nên chia đều.
    final usable = width - 18 * 2;
    final cell = usable / length;
    final centerX = cell * index + cell / 2;

    // bubble size 54 -> trừ nửa kích thước để ra left
    return 18 + centerX - 54 / 2;
  }
}

class _ActiveBubble extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ActiveBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}
