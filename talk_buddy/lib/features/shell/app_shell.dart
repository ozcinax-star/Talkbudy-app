import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class ShellTab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const ShellTab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const childTabs = [
  ShellTab(
    path: '/child',
    icon: Icons.route_outlined,
    activeIcon: Icons.route_rounded,
    label: 'Öğren',
  ),
  ShellTab(
    path: '/child/activities',
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'Sohbet',
  ),
  ShellTab(
    path: '/child/rewards',
    icon: Icons.star_outline_rounded,
    activeIcon: Icons.star_rounded,
    label: 'Rozetler',
  ),
];

const parentTabs = [
  ShellTab(
    path: '/parent',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights_rounded,
    label: 'Panel',
  ),
  ShellTab(
    path: '/parent/sessions',
    icon: Icons.article_outlined,
    activeIcon: Icons.article_rounded,
    label: 'Seanslar',
  ),
  ShellTab(
    path: '/parent/settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Ayarlar',
  ),
];

const teacherTabs = [
  ShellTab(
    path: '/teacher',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    label: 'Sınıfım',
  ),
  ShellTab(
    path: '/teacher/reports',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights_rounded,
    label: 'Raporlar',
  ),
  ShellTab(
    path: '/teacher/settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Ayarlar',
  ),
];

const specialistTabs = [
  ShellTab(
    path: '/specialist',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    label: 'Danışanlar',
  ),
  ShellTab(
    path: '/specialist/alerts',
    icon: Icons.notifications_none_rounded,
    activeIcon: Icons.notifications_rounded,
    label: 'Uyarılar',
  ),
  ShellTab(
    path: '/specialist/settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Ayarlar',
  ),
];

class AppShell extends StatelessWidget {
  final Widget child;
  final List<ShellTab> tabs;
  final Color background;
  final int badgeIndex;
  final int badgeCount;

  const AppShell({
    super.key,
    required this.child,
    required this.tabs,
    this.background = AppColors.canvas,
    this.badgeIndex = -1,
    this.badgeCount = 0,
  });

  int _indexOf(String location) {
    var best = 0;
    var bestLen = -1;
    for (var i = 0; i < tabs.length; i++) {
      final p = tabs[i].path;
      if (location == p || location.startsWith('$p/')) {
        if (p.length > bestLen) {
          bestLen = p.length;
          best = i;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexOf(location);

    return Scaffold(
      backgroundColor: background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: tabs[i],
                      selected: i == index,
                      badge: i == badgeIndex ? badgeCount : 0,
                      onTap: () {
                        if (i != index) context.go(tabs[i].path);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final ShellTab tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.inkSoft;
    return InkResponse(
      onTap: onTap,
      radius: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 24,
                  color: color,
                ),
              ),
              if (badge > 0)
                Positioned(
                  right: -7,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
