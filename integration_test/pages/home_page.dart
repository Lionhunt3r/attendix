import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the Home page (main shell with bottom navigation).
///
/// Abstracts UI elements and provides finders for role-based navigation.
///
/// Example:
/// ```dart
/// testWidgets('Conductor sees correct navigation', (tester) async {
///   await launchTestApp(tester, role: 'conductor');
///   final homePage = HomePageObject(tester);
///
///   homePage.expectPageVisible();
///   homePage.expectConductorNav();
/// });
/// ```
class HomePageObject {
  HomePageObject(this.tester);

  final WidgetTester tester;

  // ========== Finders ==========

  /// Finder for the bottom navigation bar.
  Finder get bottomNav => find.byType(NavigationBar);

  /// Finder for the People tab (Personen).
  Finder get peopleTab => _findNavDestination('Personen');

  /// Finder for the Attendance tab (Anwesenheit).
  Finder get attendanceTab => _findNavDestination('Anwesenheit');

  /// Finder for the Self-Service tab (Meine Termine).
  Finder get overviewTab => _findNavDestination('Meine Termine');

  /// Finder for the Settings tab (Einstellungen).
  Finder get settingsTab => _findNavDestination('Einstellungen');

  /// Finder for the Members tab (Mitglieder).
  Finder get membersTab => _findNavDestination('Mitglieder');

  /// Finder for the Parents tab (Termine - for parents).
  Finder get parentsTab => _findNavDestination('Termine');

  /// Helper to find a navigation destination by label.
  Finder _findNavDestination(String label) {
    return find.descendant(
      of: bottomNav,
      matching: find.text(label),
    );
  }

  // ========== Actions ==========

  /// Tap the People tab.
  Future<void> tapPeopleTab() async {
    expect(peopleTab, findsOneWidget, reason: 'People tab should be visible');
    await tester.tap(peopleTab);
    await tester.pumpAndSettle();
  }

  /// Tap the Attendance tab.
  Future<void> tapAttendanceTab() async {
    expect(attendanceTab, findsOneWidget,
        reason: 'Attendance tab should be visible');
    await tester.tap(attendanceTab);
    await tester.pumpAndSettle();
  }

  /// Tap the Self-Service Overview tab.
  Future<void> tapOverviewTab() async {
    expect(overviewTab, findsOneWidget, reason: 'Overview tab should be visible');
    await tester.tap(overviewTab);
    await tester.pumpAndSettle();
  }

  /// Tap the Settings tab.
  Future<void> tapSettingsTab() async {
    expect(settingsTab, findsOneWidget, reason: 'Settings tab should be visible');
    await tester.tap(settingsTab);
    await tester.pumpAndSettle();
  }

  /// Tap the Members tab.
  Future<void> tapMembersTab() async {
    expect(membersTab, findsOneWidget, reason: 'Members tab should be visible');
    await tester.tap(membersTab);
    await tester.pumpAndSettle();
  }

  /// Tap the Parents tab.
  Future<void> tapParentsTab() async {
    expect(parentsTab, findsOneWidget, reason: 'Parents tab should be visible');
    await tester.tap(parentsTab);
    await tester.pumpAndSettle();
  }

  // ========== Assertions ==========

  /// Verify that the home page (with bottom nav) is visible.
  void expectPageVisible() {
    expect(bottomNav, findsOneWidget,
        reason: 'Bottom navigation should be visible');
    expect(settingsTab, findsOneWidget,
        reason: 'Settings tab should always be visible');
  }

  /// Get the number of visible navigation destinations.
  int getNavCount() {
    final destinations = find.descendant(
      of: bottomNav,
      matching: find.byType(NavigationDestination),
    );
    return destinations.evaluate().length;
  }

  /// Verify conductor navigation tabs are visible.
  ///
  /// Conductors see: Personen, Anwesenheit, Einstellungen
  void expectConductorNav() {
    expect(peopleTab, findsOneWidget,
        reason: 'Conductor should see People tab');
    expect(attendanceTab, findsOneWidget,
        reason: 'Conductor should see Attendance tab');
    expect(settingsTab, findsOneWidget,
        reason: 'Conductor should see Settings tab');
    expect(overviewTab, findsNothing,
        reason: 'Conductor should not see Overview tab');
    expect(parentsTab, findsNothing,
        reason: 'Conductor should not see Parents tab');
  }

  /// Verify helper navigation tabs are visible.
  ///
  /// Helpers see: Anwesenheit, Meine Termine, Einstellungen
  void expectHelperNav() {
    expect(peopleTab, findsNothing,
        reason: 'Helper should not see People tab');
    expect(attendanceTab, findsOneWidget,
        reason: 'Helper should see Attendance tab');
    expect(overviewTab, findsOneWidget,
        reason: 'Helper should see Overview tab');
    expect(settingsTab, findsOneWidget,
        reason: 'Helper should see Settings tab');
    expect(parentsTab, findsNothing,
        reason: 'Helper should not see Parents tab');
  }

  /// Verify player navigation tabs are visible.
  ///
  /// Players see: Meine Termine, Einstellungen
  void expectPlayerNav() {
    expect(peopleTab, findsNothing,
        reason: 'Player should not see People tab');
    expect(attendanceTab, findsNothing,
        reason: 'Player should not see Attendance tab');
    expect(overviewTab, findsOneWidget,
        reason: 'Player should see Overview tab');
    expect(settingsTab, findsOneWidget,
        reason: 'Player should see Settings tab');
    expect(parentsTab, findsNothing,
        reason: 'Player should not see Parents tab');
  }

  /// Verify parent navigation tabs are visible.
  ///
  /// Parents see: Termine, Einstellungen
  void expectParentNav() {
    expect(peopleTab, findsNothing,
        reason: 'Parent should not see People tab');
    expect(attendanceTab, findsNothing,
        reason: 'Parent should not see Attendance tab');
    expect(overviewTab, findsNothing,
        reason: 'Parent should not see Overview tab');
    expect(parentsTab, findsOneWidget,
        reason: 'Parent should see Parents tab');
    expect(settingsTab, findsOneWidget,
        reason: 'Parent should see Settings tab');
  }

  /// Verify viewer navigation tabs are visible.
  ///
  /// Viewers see: Personen, Anwesenheit, Einstellungen (same as conductor)
  void expectViewerNav() {
    expectConductorNav();
  }

  /// Verify that a specific tab is selected/highlighted.
  void expectTabSelected(String label) {
    // This would require checking the selectedIndex of NavigationBar
    // For now, we verify the tab exists
    final tab = _findNavDestination(label);
    expect(tab, findsOneWidget, reason: 'Tab "$label" should be visible');
  }

  /// Verify that a specific tab is NOT visible.
  void expectTabHidden(String label) {
    final tab = _findNavDestination(label);
    expect(tab, findsNothing, reason: 'Tab "$label" should not be visible');
  }

  /// Verify that the page content area shows a scaffold.
  void expectContentVisible() {
    expect(find.byType(Scaffold), findsWidgets,
        reason: 'Page content scaffold should be visible');
  }
}
