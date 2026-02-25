import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_launcher.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'robots/navigation_robot.dart';

/// App Smoke Tests
///
/// Basic integration tests to verify the app launches and core navigation works.
///
/// Run with:
/// ```bash
/// # Run in Flutter test runner
/// flutter test integration_test/app_test.dart -d macos
///
/// # Run with Chrome driver
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_test.dart \
///   -d chrome
/// ```
void main() {
  final binding = initIntegrationTestBinding();

  // Container reference for cleanup
  ProviderContainer? container;

  tearDown(() {
    // Dispose container after each test to prevent resource leaks
    container?.dispose();
    container = null;
  });

  tearDownAll(() {
    // Report test metadata for CI
    binding.reportData = <String, dynamic>{
      'test_framework': 'integration_test',
      'test_suite': 'app_smoke_tests',
    };
  });

  group('App Smoke Tests', () {
    testWidgets('App launches and displays login page when unauthenticated',
        (tester) async {
      container = await launchUnauthenticatedApp(tester);

      final loginPage = LoginPageObject(tester);
      loginPage.expectPageVisible();
    });

    testWidgets('Login page has all required elements', (tester) async {
      container = await launchUnauthenticatedApp(tester);

      final loginPage = LoginPageObject(tester);

      // Verify all login page elements are present
      expect(loginPage.emailField, findsOneWidget);
      expect(loginPage.passwordField, findsOneWidget);
      expect(loginPage.loginButton, findsOneWidget);
      expect(loginPage.registerLink, findsOneWidget);
      expect(loginPage.forgotPasswordLink, findsOneWidget);
    });
  });

  group('Role-Based Navigation Tests', () {
    testWidgets('Conductor sees People, Attendance, and Settings tabs',
        (tester) async {
      container = await launchTestApp(tester, role: 'conductor', tenantId: 1);

      final homePage = HomePageObject(tester);
      homePage.expectPageVisible();
      homePage.expectConductorNav();
    });

    testWidgets('Helper sees Attendance, Overview, and Settings tabs',
        (tester) async {
      container = await launchTestApp(tester, role: 'helper', tenantId: 1);

      final homePage = HomePageObject(tester);
      homePage.expectPageVisible();
      homePage.expectHelperNav();
    });

    testWidgets('Player sees Overview and Settings tabs only', (tester) async {
      container = await launchTestApp(tester, role: 'player', tenantId: 1);

      final homePage = HomePageObject(tester);
      homePage.expectPageVisible();
      homePage.expectPlayerNav();
    });

    testWidgets('Parent sees Parents Portal and Settings tabs', (tester) async {
      container = await launchTestApp(tester, role: 'parent', tenantId: 1);

      final homePage = HomePageObject(tester);
      homePage.expectPageVisible();
      homePage.expectParentNav();
    });
  });

  group('Navigation Tests', () {
    testWidgets('Conductor can navigate between tabs', (tester) async {
      container = await launchTestApp(tester, role: 'conductor', tenantId: 1);

      final navRobot = NavigationRobot(tester);

      // Start on People tab (default for conductor)
      navRobot.verifyRoute('/people');

      // Navigate to Attendance
      await navRobot.goToAttendance();
      navRobot.verifyRoute('/attendance');

      // Navigate to Settings
      await navRobot.goToSettings();
      navRobot.verifyRoute('/settings');

      // Navigate back to People
      await navRobot.goToPeople();
      navRobot.verifyRoute('/people');
    });

    testWidgets('Player can navigate between their tabs', (tester) async {
      container = await launchTestApp(tester, role: 'player', tenantId: 1);

      final navRobot = NavigationRobot(tester);

      // Start on Overview tab (default for player)
      navRobot.verifyRoute('/overview');

      // Navigate to Settings
      await navRobot.goToSettings();
      navRobot.verifyRoute('/settings');

      // Navigate back to Overview
      await navRobot.goToOverview();
      navRobot.verifyRoute('/overview');
    });

    testWidgets('Helper can navigate between their tabs', (tester) async {
      container = await launchTestApp(tester, role: 'helper', tenantId: 1);

      final navRobot = NavigationRobot(tester);

      // Navigate through all helper tabs
      await navRobot.goToAttendance();
      navRobot.verifyRoute('/attendance');

      await navRobot.goToOverview();
      navRobot.verifyRoute('/overview');

      await navRobot.goToSettings();
      navRobot.verifyRoute('/settings');
    });
  });

  group('Navigation Bar Visibility Tests', () {
    testWidgets('Navigation bar is visible for authenticated users',
        (tester) async {
      container = await launchTestApp(tester, role: 'conductor', tenantId: 1);

      final navRobot = NavigationRobot(tester);
      navRobot.verifyBottomNavVisible();
    });

    testWidgets('Navigation bar is NOT visible on login page', (tester) async {
      container = await launchUnauthenticatedApp(tester);

      final navRobot = NavigationRobot(tester);
      navRobot.verifyBottomNavHidden();
    });

    testWidgets('Conductor navigation has 3 tabs', (tester) async {
      container = await launchTestApp(tester, role: 'conductor', tenantId: 1);

      final navRobot = NavigationRobot(tester);
      expect(navRobot.getNavItemCount(), 3,
          reason: 'Conductor should see 3 navigation tabs');
    });

    testWidgets('Player navigation has 2 tabs', (tester) async {
      container = await launchTestApp(tester, role: 'player', tenantId: 1);

      final navRobot = NavigationRobot(tester);
      expect(navRobot.getNavItemCount(), 2,
          reason: 'Player should see 2 navigation tabs');
    });
  });
}
