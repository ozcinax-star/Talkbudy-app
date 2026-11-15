import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/repositories/demo_data.dart';
import '../../features/auth/login_screen.dart';
import '../../features/child/activities_screen.dart';
import '../../features/child/rewards_screen.dart';
import '../../features/child/session_screen.dart';
import '../../features/learn/lesson_screen.dart';
import '../../features/learn/path_screen.dart';
import '../../features/parent/parent_dashboard_screen.dart';
import '../../features/parent/session_history_screen.dart';
import '../../features/settings/ai_settings_screen.dart';
import '../../features/settings/child_settings_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/speech_settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/specialist/alerts_screen.dart';
import '../../features/specialist/child_detail_screen.dart';
import '../../features/specialist/specialist_dashboard_screen.dart';
import '../../features/teacher/teacher_dashboard_screen.dart';
import '../theme/app_theme.dart';

final _rootKey = GlobalKey<NavigatorState>();

Page<void> _fade(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, page) =>
          FadeTransition(opacity: animation, child: page),
    );

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const LoginScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => AppShell(
        tabs: childTabs,
        background: const Color(0xFFF2F4FF),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/child',
          pageBuilder: (_, __) => _fade(const PathScreen()),
        ),
        GoRoute(
          path: '/child/activities',
          pageBuilder: (_, __) => _fade(const ActivitiesScreen()),
        ),
        GoRoute(
          path: '/child/rewards',
          pageBuilder: (_, __) => _fade(const RewardsScreen()),
        ),
      ],
    ),

    GoRoute(
      path: '/lesson/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          LessonScreen(lessonId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/session',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => SessionScreen(
        activity: state.extra as Activity? ?? DemoData.activities.first,
      ),
    ),

    ShellRoute(
      builder: (context, state, child) => AppShell(
        tabs: parentTabs,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/parent',
          pageBuilder: (_, __) => _fade(const ParentDashboardScreen()),
        ),
        GoRoute(
          path: '/parent/sessions',
          pageBuilder: (_, __) => _fade(const SessionHistoryScreen()),
        ),
        GoRoute(
          path: '/parent/settings',
          pageBuilder: (_, __) => _fade(const SettingsScreen()),
        ),
      ],
    ),

    ShellRoute(
      builder: (context, state, child) => AppShell(
        tabs: teacherTabs,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/teacher',
          pageBuilder: (_, __) => _fade(const TeacherDashboardScreen()),
        ),
        GoRoute(
          path: '/teacher/reports',
          pageBuilder: (_, __) => _fade(const SpecialistDashboardScreen()),
        ),
        GoRoute(
          path: '/teacher/settings',
          pageBuilder: (_, __) => _fade(const SettingsScreen()),
        ),
      ],
    ),

    GoRoute(
      path: '/teacher/student/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          TeacherStudentScreen(studentId: state.pathParameters['id']!),
    ),

    ShellRoute(
      builder: (context, state, child) => AppShell(
        tabs: specialistTabs,
        badgeIndex: 1,
        badgeCount:
            DemoData.alerts().where((a) => a.level != AlertLevel.info).length,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/specialist',
          pageBuilder: (_, __) => _fade(const SpecialistDashboardScreen()),
        ),
        GoRoute(
          path: '/specialist/alerts',
          pageBuilder: (_, __) => _fade(const AlertsScreen()),
        ),
        GoRoute(
          path: '/specialist/settings',
          pageBuilder: (_, __) => _fade(const SettingsScreen()),
        ),
      ],
    ),

    GoRoute(
      path: '/specialist/child/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          ChildDetailScreen(childId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'ai',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const AiSettingsScreen(),
        ),
        GoRoute(
          path: 'speech',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const SpeechSettingsScreen(),
        ),
        GoRoute(
          path: 'child',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const ChildSettingsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.explore_off_rounded,
              size: 48,
              color: AppColors.inkSoft,
            ),
            const SizedBox(height: 16),
            Text(
              'Sayfa bulunamadı\n${state.uri}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Başa dön'),
            ),
          ],
        ),
      ),
    ),
  ),
);
