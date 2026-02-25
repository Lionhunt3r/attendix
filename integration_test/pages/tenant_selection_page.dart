import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the Tenant Selection page.
///
/// Abstracts UI elements and provides finders for the tenant selection page.
///
/// Example:
/// ```dart
/// testWidgets('Tenant selection shows tenants', (tester) async {
///   await launchAuthenticatedApp(tester);
///   final tenantPage = TenantSelectionPageObject(tester);
///
///   tenantPage.expectPageVisible();
///   tenantPage.expectTenantsVisible(2);
///   await tenantPage.selectTenant('TestOrchestra');
/// });
/// ```
class TenantSelectionPageObject {
  TenantSelectionPageObject(this.tester);

  final WidgetTester tester;

  // ========== Finders ==========

  /// Finder for the page title.
  Finder get title => find.text('Gruppe auswählen');

  /// Finder for the logout button in app bar.
  Finder get logoutButton => find.byIcon(Icons.logout);

  /// Finder for all tenant cards.
  Finder get tenantCards => find.byType(Card);

  /// Finder for the loading indicator.
  Finder get loadingIndicator => find.byType(CircularProgressIndicator);

  /// Finder for the error state.
  Finder get errorState => find.byIcon(Icons.error_outline);

  /// Finder for the empty state.
  Finder get emptyState => find.byIcon(Icons.group_off_outlined);

  /// Finder for the empty state message.
  Finder get emptyStateMessage => find.text('Keine Gruppen');

  /// Finder for the "create new group" button.
  Finder get createGroupButton => find.text('Neue Gruppe erstellen');

  /// Finder for the retry button.
  Finder get retryButton => find.text('Erneut versuchen');

  // ========== Actions ==========

  /// Select a tenant by its short name.
  Future<void> selectTenant(String shortName) async {
    final tenantText = find.textContaining(shortName);
    expect(tenantText, findsWidgets,
        reason: 'Tenant "$shortName" should be visible');

    // Find the parent Card and tap it
    final card = find.ancestor(
      of: tenantText,
      matching: find.byType(Card),
    );
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card.first);
      await tester.pumpAndSettle();
      return;
    }

    // Fallback: tap the text directly
    await tester.tap(tenantText.first);
    await tester.pumpAndSettle();
  }

  /// Tap the logout button.
  Future<void> tapLogout() async {
    expect(logoutButton, findsOneWidget,
        reason: 'Logout button should be visible');
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();
  }

  /// Tap the retry button (when in error state).
  Future<void> tapRetry() async {
    expect(retryButton, findsOneWidget, reason: 'Retry button should be visible');
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
  }

  /// Tap the "create new group" button.
  Future<void> tapCreateGroup() async {
    final button = find.widgetWithText(OutlinedButton, 'Neue Gruppe erstellen');
    expect(button, findsOneWidget,
        reason: 'Create group button should be visible');
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Scroll to find a tenant in the list.
  Future<void> scrollToTenant(String shortName) async {
    await tester.scrollUntilVisible(
      find.textContaining(shortName),
      500.0,
      scrollable: find.byType(Scrollable).first,
    );
  }

  // ========== Assertions ==========

  /// Verify that the tenant selection page is visible.
  void expectPageVisible() {
    expect(title, findsOneWidget,
        reason: 'Page title "Gruppe auswählen" should be visible');
    expect(logoutButton, findsOneWidget,
        reason: 'Logout button should be visible');
  }

  /// Verify that a specific number of tenants are visible.
  void expectTenantsVisible(int count) {
    expect(tenantCards, findsNWidgets(count),
        reason: '$count tenant cards should be visible');
  }

  /// Verify that at least one tenant is visible.
  void expectTenantsLoaded() {
    expect(tenantCards, findsWidgets,
        reason: 'At least one tenant should be visible');
  }

  /// Verify that loading indicator is shown.
  void expectLoading() {
    expect(loadingIndicator, findsOneWidget,
        reason: 'Loading indicator should be visible');
  }

  /// Verify that error state is shown.
  void expectError() {
    expect(errorState, findsOneWidget, reason: 'Error state should be visible');
    expect(retryButton, findsOneWidget,
        reason: 'Retry button should be visible in error state');
  }

  /// Verify that empty state is shown.
  void expectEmpty() {
    expect(emptyState, findsOneWidget, reason: 'Empty state should be visible');
    expect(emptyStateMessage, findsOneWidget,
        reason: 'Empty state message should be visible');
    expect(createGroupButton, findsOneWidget,
        reason: 'Create group button should be visible in empty state');
  }

  /// Verify that a specific tenant is visible.
  void expectTenantVisible(String shortName) {
    final tenantText = find.textContaining(shortName);
    expect(tenantText, findsWidgets, reason: 'Tenant "$shortName" should be visible');
  }

  /// Verify that a specific tenant is NOT visible.
  void expectTenantHidden(String shortName) {
    final tenantText = find.text(shortName);
    expect(tenantText, findsNothing,
        reason: 'Tenant "$shortName" should not be visible');
  }

  /// Verify that the page is NOT in loading state.
  void expectNotLoading() {
    expect(loadingIndicator, findsNothing,
        reason: 'Loading indicator should not be visible');
  }
}
