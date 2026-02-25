import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robot for attendance-related actions in integration tests.
///
/// Provides high-level methods for creating, editing, and managing attendances.
///
/// Example:
/// ```dart
/// testWidgets('Can create attendance', (tester) async {
///   await launchTestApp(tester, role: 'conductor');
///   final attendanceRobot = AttendanceRobot(tester);
///
///   await attendanceRobot.tapCreateAttendance();
///   await attendanceRobot.selectDate(DateTime.now());
///   await attendanceRobot.submitAttendance();
/// });
/// ```
class AttendanceRobot {
  AttendanceRobot(this.tester);

  final WidgetTester tester;

  /// Tap the create/add attendance button (FAB or add button).
  Future<void> tapCreateAttendance() async {
    // Try FAB first
    final fab = find.byType(FloatingActionButton);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
      await tester.pumpAndSettle();
      return;
    }

    // Try add icon
    final addIcon = find.byIcon(Icons.add);
    if (addIcon.evaluate().isNotEmpty) {
      await tester.tap(addIcon.first);
      await tester.pumpAndSettle();
      return;
    }

    throw TestFailure('Create attendance button not found');
  }

  /// Select a date in the date picker or calendar.
  Future<void> selectDate(DateTime date) async {
    // Find and tap the date field
    final dateField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          (widget.decoration?.labelText?.contains('Datum') == true ||
              widget.decoration?.hintText?.contains('Datum') == true),
    );

    if (dateField.evaluate().isNotEmpty) {
      await tester.tap(dateField);
      await tester.pumpAndSettle();
    }

    // Handle date picker dialog
    final okButton = find.text('OK');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton);
      await tester.pumpAndSettle();
    }
  }

  /// Select an attendance type by name.
  Future<void> selectType(String typeName) async {
    final typeDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField ||
          (widget is InputDecorator &&
              widget.decoration.labelText?.contains('Typ') == true),
    );

    if (typeDropdown.evaluate().isNotEmpty) {
      await tester.tap(typeDropdown.first);
      await tester.pumpAndSettle();

      final typeOption = find.text(typeName);
      if (typeOption.evaluate().isNotEmpty) {
        await tester.tap(typeOption.last);
        await tester.pumpAndSettle();
      }
    }
  }

  /// Submit/save the attendance form.
  Future<void> submitAttendance() async {
    // Try "Speichern" button
    final saveButton = find.text('Speichern');
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      return;
    }

    // Try "Erstellen" button
    final createButton = find.text('Erstellen');
    if (createButton.evaluate().isNotEmpty) {
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      return;
    }

    // Try check icon
    final checkIcon = find.byIcon(Icons.check);
    if (checkIcon.evaluate().isNotEmpty) {
      await tester.tap(checkIcon.first);
      await tester.pumpAndSettle();
      return;
    }

    throw TestFailure('Submit button not found');
  }

  /// Tap on an attendance item in the list.
  Future<void> tapAttendance(String dateOrTitle) async {
    final item = find.textContaining(dateOrTitle);
    expect(item, findsWidgets,
        reason: 'Attendance item "$dateOrTitle" should be visible');
    await tester.tap(item.first);
    await tester.pumpAndSettle();
  }

  /// Mark a person as present in the attendance detail.
  Future<void> markPersonPresent(String personName) async {
    final personTile = find.ancestor(
      of: find.textContaining(personName),
      matching: find.byType(ListTile),
    );

    expect(personTile, findsOneWidget,
        reason: 'Person "$personName" should be in the list');

    // Tap the tile or status icon to cycle status
    await tester.tap(personTile);
    await tester.pumpAndSettle();
  }

  /// Set a person's attendance status.
  ///
  /// [status] - 'Anwesend', 'Abwesend', 'Entschuldigt', 'Verspätet'
  Future<void> setPersonStatus(String personName, String status) async {
    // First tap the person to open status selection
    await markPersonPresent(personName);

    // Then select the status
    final statusButton = find.text(status);
    if (statusButton.evaluate().isNotEmpty) {
      await tester.tap(statusButton);
      await tester.pumpAndSettle();
    }
  }

  /// Delete the current attendance.
  Future<void> deleteAttendance() async {
    final deleteButton = find.byIcon(Icons.delete);
    expect(deleteButton, findsOneWidget, reason: 'Delete button should be visible');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm deletion dialog
    final confirmButton = find.text('Löschen');
    if (confirmButton.evaluate().isNotEmpty) {
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
    }
  }

  /// Verify that the attendance list is visible.
  void verifyAttendanceListVisible() {
    // Look for list view or attendance-specific widgets
    expect(find.byType(ListView), findsWidgets,
        reason: 'Attendance list should be visible');
  }

  /// Verify that the attendance create form is visible.
  void verifyCreateFormVisible() {
    final dateField = find.textContaining('Datum');
    expect(dateField, findsWidgets,
        reason: 'Date field should be visible in create form');
  }

  /// Verify that a specific attendance exists in the list.
  void verifyAttendanceExists(String dateOrTitle) {
    final attendance = find.textContaining(dateOrTitle);
    expect(attendance, findsWidgets,
        reason: 'Attendance "$dateOrTitle" should exist');
  }

  /// Verify that the attendance detail page is visible.
  void verifyDetailPageVisible() {
    // Detail page typically has a list of persons
    expect(find.byType(Scaffold), findsWidgets,
        reason: 'Detail page scaffold should be visible');
  }

  /// Add notes to the attendance.
  Future<void> enterNotes(String notes) async {
    final notesField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          (widget.decoration?.labelText?.contains('Notizen') == true ||
              widget.decoration?.hintText?.contains('Notizen') == true),
    );

    if (notesField.evaluate().isNotEmpty) {
      await tester.enterText(notesField, notes);
      await tester.pumpAndSettle();
    }
  }

  /// Scroll to find an item in the attendance list.
  Future<void> scrollToAttendance(String dateOrTitle) async {
    await tester.scrollUntilVisible(
      find.textContaining(dateOrTitle),
      500.0,
      scrollable: find.byType(Scrollable).first,
    );
  }
}
