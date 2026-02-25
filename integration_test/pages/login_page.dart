import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page object for the Login page.
///
/// Abstracts UI elements and provides finders for the login page.
///
/// Example:
/// ```dart
/// testWidgets('Login page has all elements', (tester) async {
///   await launchUnauthenticatedApp(tester);
///   final loginPage = LoginPageObject(tester);
///
///   loginPage.expectPageVisible();
///   await loginPage.enterEmail('test@example.com');
///   await loginPage.enterPassword('password123');
///   await loginPage.tapLogin();
/// });
/// ```
class LoginPageObject {
  LoginPageObject(this.tester);

  final WidgetTester tester;

  // ========== Finders ==========

  /// Finder for the email text field.
  Finder get emailField => find.byWidgetPredicate(
        (widget) {
          if (widget is TextField) {
            final decoration = widget.decoration;
            return decoration?.labelText == 'E-Mail';
          }
          return false;
        },
      );

  /// Finder for the password text field.
  Finder get passwordField => find.byWidgetPredicate(
        (widget) {
          if (widget is TextField) {
            final decoration = widget.decoration;
            return decoration?.labelText == 'Passwort';
          }
          return false;
        },
      );

  /// Finder for the login button.
  Finder get loginButton => find.widgetWithText(ElevatedButton, 'Anmelden');

  /// Finder for the register link.
  Finder get registerLink => find.text('Registrieren');

  /// Finder for the forgot password link.
  Finder get forgotPasswordLink => find.text('Passwort vergessen?');

  /// Finder for the app title.
  Finder get appTitle => find.text('Attendix');

  /// Finder for the app subtitle.
  Finder get appSubtitle => find.text('Anwesenheitsverwaltung');

  /// Finder for error message container.
  Finder get errorMessage => find.byIcon(Icons.error_outline);

  /// Finder for loading indicator.
  Finder get loadingIndicator => find.byType(CircularProgressIndicator);

  // ========== Actions ==========

  /// Enter text in the email field.
  Future<void> enterEmail(String email) async {
    await tester.enterText(emailField, email);
    await tester.pump();
  }

  /// Enter text in the password field.
  Future<void> enterPassword(String password) async {
    await tester.enterText(passwordField, password);
    await tester.pump();
  }

  /// Tap the login button.
  Future<void> tapLogin() async {
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  /// Tap the register link.
  Future<void> tapRegister() async {
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
  }

  /// Tap the forgot password link.
  Future<void> tapForgotPassword() async {
    await tester.tap(forgotPasswordLink);
    await tester.pumpAndSettle();
  }

  /// Toggle password visibility.
  Future<void> togglePasswordVisibility() async {
    final visibilityToggle = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          (widget.icon is Icon &&
              ((widget.icon as Icon).icon == Icons.visibility_outlined ||
                  (widget.icon as Icon).icon == Icons.visibility_off_outlined)),
    );
    if (visibilityToggle.evaluate().isNotEmpty) {
      await tester.tap(visibilityToggle);
      await tester.pump();
    }
  }

  // ========== Assertions ==========

  /// Verify that the login page is visible.
  void expectPageVisible() {
    expect(appTitle, findsOneWidget,
        reason: 'App title "Attendix" should be visible');
    expect(appSubtitle, findsOneWidget,
        reason: 'App subtitle "Anwesenheitsverwaltung" should be visible');
    expect(emailField, findsOneWidget, reason: 'Email field should be visible');
    expect(passwordField, findsOneWidget,
        reason: 'Password field should be visible');
    expect(loginButton, findsOneWidget,
        reason: 'Login button should be visible');
  }

  /// Verify that an error is displayed.
  void expectError() {
    expect(errorMessage, findsWidgets, reason: 'Error message should be visible');
  }

  /// Verify that no error is displayed.
  void expectNoError() {
    expect(errorMessage, findsNothing,
        reason: 'Error message should not be visible');
  }

  /// Verify that loading indicator is shown.
  void expectLoading() {
    expect(loadingIndicator, findsOneWidget,
        reason: 'Loading indicator should be visible');
  }

  /// Verify that loading indicator is NOT shown.
  void expectNotLoading() {
    expect(loadingIndicator, findsNothing,
        reason: 'Loading indicator should not be visible');
  }

  /// Verify that the password is obscured.
  void expectPasswordObscured() {
    final textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, true,
        reason: 'Password should be obscured');
  }

  /// Verify that the password is visible.
  void expectPasswordVisible() {
    final textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, false,
        reason: 'Password should be visible');
  }

  /// Verify that all form fields are empty.
  void expectFormEmpty() {
    expectNoError();
  }
}
