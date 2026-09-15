import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/dash_text_styles.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

const List<_NavItem> _navItems = [
  _NavItem(Icons.home_outlined, Icons.home, 'Home'),
  _NavItem(Icons.folder_outlined, Icons.folder, 'Projects'),
  _NavItem(Icons.grid_view_outlined, Icons.grid_view, 'Dashboard'),
  _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
  _NavItem(Icons.person_outline, Icons.person, 'Profile'),
];

/// شريط التنقل السفلي (Home / Projects / Dashboard / AI / Profile)،
/// نفس المكون مكرر بكل شاشات الـ Dashboard حسب الـ design system
class ScaleFlowBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const ScaleFlowBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: const Border(
            top: BorderSide(color: Color(0xFFE9ECEE)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = index == currentIndex;
            final color =
                isActive ? AppColors.dataCyan : const Color(0xFF9AA5AF);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap?.call(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isActive ? item.activeIcon : item.icon,
                        size: 22, color: color),
                    const SizedBox(height: 3),
                    Text(item.label,
                        style: DashTextStyles.navLabel(color: color)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
