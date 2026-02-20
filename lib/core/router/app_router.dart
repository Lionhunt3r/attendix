import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/supabase_config.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/tenant_selection/presentation/pages/tenant_selection_page.dart';
import '../../features/tenant_selection/presentation/pages/tenant_create_page.dart';
import '../../shared/widgets/layout/main_shell.dart';
import '../../features/people/presentation/pages/people_list_page.dart';
import '../../features/people/presentation/pages/person_detail_page.dart';
import '../../features/people/presentation/pages/person_create_page.dart';
import '../../features/attendance/presentation/pages/attendance_list_page.dart';
import '../../features/attendance/presentation/pages/attendance_detail_page.dart';
import '../../features/attendance/presentation/pages/attendance_create_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/general_settings_page.dart';
import '../../features/settings/presentation/pages/attendance_types_page.dart';
import '../../features/settings/presentation/pages/attendance_type_edit_page.dart';
import '../../features/settings/presentation/pages/user_management_page.dart';
import '../../features/settings/presentation/pages/pending_players_page.dart';
import '../../features/settings/presentation/pages/left_players_page.dart';
import '../../features/settings/presentation/pages/calendar_subscription_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/teachers/presentation/pages/teachers_list_page.dart';
import '../../features/export/presentation/pages/export_page.dart';
import '../../features/songs/presentation/pages/songs_list_page.dart';
import '../../features/songs/presentation/pages/song_detail_page.dart';
import '../../features/instruments/presentation/pages/instruments_list_page.dart';
import '../../features/self_service/presentation/pages/self_service_overview_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/planning/presentation/pages/planning_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/meetings/presentation/pages/meetings_list_page.dart';
import '../../features/voice_leader/presentation/pages/voice_leader_page.dart';
import '../../features/members/presentation/pages/members_page.dart';
import '../../features/registration/presentation/pages/tenant_registration_page.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.whenOrNull(
        data: (auth) => auth.session != null,
      ) ?? false;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // Public tenant registration route - allow access without login
      final isTenantRegistration = state.matchedLocation.startsWith('/register/');

      // If not logged in and not on auth route or tenant registration, redirect to login
      if (!isLoggedIn && !isAuthRoute && !isTenantRegistration) {
        return '/login';
      }

      // If logged in and on auth route, redirect to tenant selection
      if (isLoggedIn && isAuthRoute) {
        return '/tenants';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Public tenant registration (no auth required)
      GoRoute(
        path: '/register/:id',
        name: 'tenantRegistration',
        builder: (context, state) {
          final registerId = state.pathParameters['id'] ?? '';
          return TenantRegistrationPage(registerId: registerId);
        },
      ),

      // Tenant selection
      GoRoute(
        path: '/tenants',
        name: 'tenants',
        builder: (context, state) => const TenantSelectionPage(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'tenantCreate',
            builder: (context, state) => const TenantCreatePage(),
          ),
        ],
      ),

      // Main app shell with tabs
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // People/Players
          GoRoute(
            path: '/people',
            name: 'people',
            builder: (context, state) => const PeopleListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'personCreate',
                builder: (context, state) => const PersonCreatePage(),
              ),
              GoRoute(
                path: ':id',
                name: 'personDetail',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const Scaffold(
                      body: Center(child: Text('Ungültige Person-ID')),
                    );
                  }
                  return PersonDetailPage(personId: id);
                },
              ),
            ],
          ),

          // Attendance
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            builder: (context, state) => const AttendanceListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'attendanceCreate',
                builder: (context, state) => const AttendanceCreatePage(),
              ),
              GoRoute(
                path: ':id',
                name: 'attendanceDetail',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const Scaffold(
                      body: Center(child: Text('Ungültige Anwesenheits-ID')),
                    );
                  }
                  return AttendanceDetailPage(attendanceId: id);
                },
              ),
            ],
          ),

          // Self-Service Overview (for players)
          GoRoute(
            path: '/overview',
            name: 'selfServiceOverview',
            builder: (context, state) => const SelfServiceOverviewPage(),
          ),

          // Members (for players/helpers when showMembersList is enabled)
          GoRoute(
            path: '/members',
            name: 'members',
            builder: (context, state) => const MembersPage(),
          ),

          // Statistics
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsPage(),
          ),

          // Planning
          GoRoute(
            path: '/planning',
            name: 'planning',
            builder: (context, state) {
              final attendanceId = int.tryParse(
                state.uri.queryParameters['attendanceId'] ?? '',
              );
              return PlanningPage(attendanceId: attendanceId);
            },
          ),

          // History
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryPage(),
          ),

          // Export
          GoRoute(
            path: '/export',
            name: 'export',
            builder: (context, state) => const ExportPage(),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
              GoRoute(
                path: 'songs',
                name: 'songs',
                builder: (context, state) => const SongsListPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'songDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      if (id == null) return const SongsListPage();
                      return SongDetailPage(songId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'instruments',
                name: 'instruments',
                builder: (context, state) => const InstrumentsListPage(),
              ),
              GoRoute(
                path: 'teachers',
                name: 'teachers',
                builder: (context, state) => const TeachersListPage(),
              ),
              GoRoute(
                path: 'meetings',
                name: 'meetings',
                builder: (context, state) => const MeetingsListPage(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsPage(),
              ),
              GoRoute(
                path: 'general',
                name: 'general',
                builder: (context, state) => const GeneralSettingsPage(),
              ),
              GoRoute(
                path: 'users',
                name: 'users',
                builder: (context, state) => const UserManagementPage(),
              ),
              GoRoute(
                path: 'types',
                name: 'attendanceTypes',
                builder: (context, state) => const AttendanceTypesPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'attendanceTypeEdit',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      if (id == null) return const AttendanceTypesPage();
                      return AttendanceTypeEditPage(typeId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'pending',
                name: 'pendingPlayers',
                builder: (context, state) => const PendingPlayersPage(),
              ),
              GoRoute(
                path: 'left',
                name: 'leftPlayers',
                builder: (context, state) => const LeftPlayersPage(),
              ),
              GoRoute(
                path: 'calendar',
                name: 'calendarSubscription',
                builder: (context, state) => const CalendarSubscriptionPage(),
              ),
              GoRoute(
                path: 'voice-leader',
                name: 'voiceLeader',
                builder: (context, state) => const VoiceLeaderPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/people'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Route names for type-safe navigation
class AppRoutes {
  AppRoutes._();

  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String tenants = 'tenants';
  static const String people = 'people';
  static const String personDetail = 'personDetail';
  static const String attendance = 'attendance';
  static const String attendanceDetail = 'attendanceDetail';
  static const String attendanceCreate = 'attendanceCreate';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String songs = 'songs';
  static const String songDetail = 'songDetail';
  static const String instruments = 'instruments';
  static const String teachers = 'teachers';
  static const String meetings = 'meetings';
  static const String notifications = 'notifications';
  static const String general = 'general';
  static const String statistics = 'statistics';
  static const String planning = 'planning';
  static const String history = 'history';
}