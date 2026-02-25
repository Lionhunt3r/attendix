import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Robot for navigation-related actions in integration tests.
///
/// Provides high-level methods for navigating between tabs and verifying routes.
///
/// Example:
/// ```dart
/// testWidgets('Can navigate between tabs', (tester) async {
///   await launchTestApp(tester, role: 'conductor');
///   final navRobot = NavigationRobot(tester);
///
///   await navRobot.goToAttendance();
///   navRobot.verifyRoute('/attendance');
/// });
/// ```
class NavigationRobot {
  NavigationRobot(this.tester);

  final WidgetTester tester;

  /// Default timeout for navigation actions.
  static const _defaultTimeout = Duration(seconds: 10);

  /// Navigate to the People tab.
  ///
  /// Only visible for conductors (admin, responsible, viewer).
  Future<void> goToPeople() async {
    await _tapNavItem('Personen');
  }

  /// Navigate to the Attendance tab.
  ///
  /// Visible for conductors and helpers.
  Future<void> goToAttendance() async {
    await _tapNavItem('Anwesenheit');
  }

  /// Navigate to the Self-Service Overview tab.
  ///
  /// Visible for players and helpers.
  Future<void> goToOverview() async {
    await _tapNavItem('Meine Termine');
  }

  /// Navigate to the Settings tab.
  ///
  /// Visible for all authenticated users.
  Future<void> goToSettings() async {
    await _tapNavItem('Einstellungen');
  }

  /// Navigate to the Members tab.
  ///
  /// Only visible if tenant has showMembersList enabled.
  Future<void> goToMembers() async {
    await _tapNavItem('Mitglieder');
  }

  /// Navigate to the Parents Portal tab.
  ///
  /// Only visible for parent role.
  Future<void> goToParentsPortal() async {
    await _tapNavItem('Termine');
  }

  /// Tap a navigation item by its label.
  Future<void> _tapNavItem(String label) async {
    final navItem = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

    expect(navItem, findsOneWidget,
        reason: 'Navigation item "$label" should be visible');

    await tester.tap(navItem);
    await tester.pumpAndSettle(_defaultTimeout);
  }

  /// Verify the current route matches the expected path.
  ///
  /// [expectedPath] - The expected route path (e.g., '/people', '/attendance')
  void verifyRoute(String expectedPath) {
    final context = tester.element(find.byType(MaterialApp).first);

    // Get the current location from GoRouter
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.fullPath;

    expect(currentLocation, startsWith(expectedPath),
        reason: 'Current route should be $expectedPath but was $currentLocation');
  }

  /// Verify that a specific navigation item is visible.
  void verifyNavItemVisible(String label) {
    final navItem = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    expect(navItem, findsOneWidget,
        reason: 'Navigation item "$label" should be visible');
  }

  /// Verify that a specific navigation item is NOT visible.
  void verifyNavItemHidden(String label) {
    final navItem = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    expect(navItem, findsNothing,
        reason: 'Navigation item "$label" should not be visible');
  }

  /// Verify the bottom navigation bar is visible.
  void verifyBottomNavVisible() {
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'Bottom navigation bar should be visible');
  }

  /// Verify the bottom navigation bar is NOT visible (e.g., on login page).
  void verifyBottomNavHidden() {
    expect(find.byType(NavigationBar), findsNothing,
        reason: 'Bottom navigation bar should not be visible');
  }

  /// Get the number of visible navigation destinations.
  int getNavItemCount() {
    final navBar = find.byType(NavigationBar);
    if (navBar.evaluate().isEmpty) return 0;

    final destinations = find.descendant(
      of: navBar,
      matching: find.byType(NavigationDestination),
    );
    return destinations.evaluate().length;
  }

  /// Tap the back button if visible.
  Future<void> goBack() async {
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle(_defaultTimeout);
      return;
    }

    // Try icon-based back button
    final backIcon = find.byIcon(Icons.arrow_back);
    if (backIcon.evaluate().isNotEmpty) {
      await tester.tap(backIcon.first);
      await tester.pumpAndSettle(_defaultTimeout);
      return;
    }

    throw TestFailure('Back button not found');
  }

  /// Verify conductor navigation (People, Attendance, Settings).
  void verifyConductorNavigation() {
    verifyNavItemVisible('Personen');
    verifyNavItemVisible('Anwesenheit');
    verifyNavItemVisible('Einstellungen');
    verifyNavItemHidden('Meine Termine');
    verifyNavItemHidden('Termine'); // Parent-only
  }

  /// Verify helper navigation (Attendance, Meine Termine, Settings).
  void verifyHelperNavigation() {
    verifyNavItemHidden('Personen');
    verifyNavItemVisible('Anwesenheit');
    verifyNavItemVisible('Meine Termine');
    verifyNavItemVisible('Einstellungen');
  }

  /// Verify player navigation (Meine Termine, Settings).
  void verifyPlayerNavigation() {
    verifyNavItemHidden('Personen');
    verifyNavItemHidden('Anwesenheit');
    verifyNavItemVisible('Meine Termine');
    verifyNavItemVisible('Einstellungen');
  }

  /// Verify parent navigation (Termine, Settings).
  void verifyParentNavigation() {
    verifyNavItemHidden('Personen');
    verifyNavItemHidden('Anwesenheit');
    verifyNavItemHidden('Meine Termine');
    verifyNavItemVisible('Termine');
    verifyNavItemVisible('Einstellungen');
  }
}
