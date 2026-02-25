import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robot for authentication-related actions in integration tests.
///
/// Provides high-level methods for login, logout, and auth verification.
///
/// Example:
/// ```dart
/// testWidgets('User can log out', (tester) async {
///   await launchTestApp(tester, role: 'conductor');
///   final authRobot = AuthRobot(tester);
///
///   await authRobot.tapLogout();
///   authRobot.verifyLoginPageVisible();
/// });
/// ```
class AuthRobot {
  AuthRobot(this.tester);

  final WidgetTester tester;

  /// Enter email in the login form.
  Future<void> enterEmail(String email) async {
    final emailField = find.byWidgetPredicate(
      (widget) {
        if (widget is TextField) {
          final decoration = widget.decoration;
          return decoration?.labelText == 'E-Mail' ||
              decoration?.hintText?.contains('E-Mail') == true;
        }
        return false;
      },
    );
    await tester.enterText(emailField, email);
    await tester.pump();
  }

  /// Enter password in the login form.
  Future<void> enterPassword(String password) async {
    final passwordField = find.byWidgetPredicate(
      (widget) {
        if (widget is TextField) {
          final decoration = widget.decoration;
          return decoration?.labelText == 'Passwort' ||
              decoration?.hintText?.contains('Passwort') == true;
        }
        return false;
      },
    );
    await tester.enterText(passwordField, password);
    await tester.pump();
  }

  /// Tap the login button.
  Future<void> tapLoginButton() async {
    final loginButton = find.widgetWithText(ElevatedButton, 'Anmelden');
    expect(loginButton, findsOneWidget, reason: 'Login button should be visible');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  /// Perform a full login flow with email and password.
  ///
  /// Note: In mock mode, this won't actually authenticate.
  /// Use [launchTestApp] with a role for pre-authenticated tests.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await enterEmail(email);
    await enterPassword(password);
    await tapLoginButton();
  }

  /// Tap the logout button (usually in settings or app bar).
  Future<void> tapLogout() async {
    // Try finding logout in different locations
    final logoutButton = find.byIcon(Icons.logout);
    if (logoutButton.evaluate().isNotEmpty) {
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      return;
    }

    // Try text-based logout
    final logoutText = find.text('Abmelden');
    if (logoutText.evaluate().isNotEmpty) {
      await tester.tap(logoutText);
      await tester.pumpAndSettle();
      return;
    }

    throw TestFailure('Logout button not found');
  }

  /// Tap the register link on the login page.
  Future<void> tapRegisterLink() async {
    final registerLink = find.text('Registrieren');
    expect(registerLink, findsOneWidget, reason: 'Register link should be visible');
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
  }

  /// Tap the forgot password link on the login page.
  Future<void> tapForgotPasswordLink() async {
    final forgotLink = find.text('Passwort vergessen?');
    expect(forgotLink, findsOneWidget, reason: 'Forgot password link should be visible');
    await tester.tap(forgotLink);
    await tester.pumpAndSettle();
  }

  /// Verify that the login page is currently visible.
  void verifyLoginPageVisible() {
    // Look for characteristic elements of the login page
    expect(find.text('Attendix'), findsOneWidget,
        reason: 'Attendix title should be visible on login page');
    expect(find.text('Anmelden'), findsWidgets,
        reason: 'Anmelden button/text should be visible');
  }

  /// Verify that the user is authenticated (not on login page).
  void verifyAuthenticated() {
    // The login page should not be visible
    expect(find.text('Anwesenheitsverwaltung'), findsNothing,
        reason: 'Login page subtitle should not be visible when authenticated');
  }

  /// Verify that an error message is displayed.
  void verifyErrorVisible([String? message]) {
    final errorIcon = find.byIcon(Icons.error_outline);
    expect(errorIcon, findsWidgets, reason: 'Error icon should be visible');

    if (message != null) {
      expect(find.textContaining(message), findsOneWidget,
          reason: 'Error message "$message" should be visible');
    }
  }
}
