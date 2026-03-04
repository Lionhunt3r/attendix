import 'package:attendix/core/constants/enums.dart';
import 'package:attendix/features/attendance/presentation/widgets/attendance_detail/attendance_person_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../factories/test_factories.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  widgetTestGroup('AttendancePersonTile', () {
    final person = TestFactories.createPerson(
      id: 1,
      firstName: 'Max',
      lastName: 'Mustermann',
    );

    Widget buildTile({
      AttendanceStatus status = AttendanceStatus.present,
      String? notes,
    }) {
      return Scaffold(
        body: AttendancePersonTile(
          person: person,
          status: status,
          notes: notes,
          availableStatuses: AttendanceStatus.values,
          onStatusChanged: (_) {},
          onNoteChanged: (_) {},
          onShowModifierInfo: () {},
          onRemoveFromAttendance: () {},
        ),
      );
    }

    group('notes display', () {
      widgetTest('shows note text when notes are present', (tester) async {
        await tester.pumpApp(
          buildTile(
            status: AttendanceStatus.late,
            notes: 'kommt erst um 19:30',
          ),
        );

        // The note text should be visible directly in the tile
        expect(find.text('kommt erst um 19:30'), findsOneWidget);
      });

      widgetTest('shows sticky note icon when notes are present', (tester) async {
        await tester.pumpApp(
          buildTile(
            status: AttendanceStatus.excused,
            notes: 'Arzttermin',
          ),
        );

        expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
      });

      widgetTest('does not show note text when notes are null', (tester) async {
        await tester.pumpApp(
          buildTile(
            status: AttendanceStatus.present,
            notes: null,
          ),
        );

        // No sticky note icon should be shown
        expect(find.byIcon(Icons.sticky_note_2), findsNothing);
      });

      widgetTest('does not show note text when notes are empty', (tester) async {
        await tester.pumpApp(
          buildTile(
            status: AttendanceStatus.present,
            notes: '',
          ),
        );

        expect(find.byIcon(Icons.sticky_note_2), findsNothing);
      });

      widgetTest('note text is styled as italic', (tester) async {
        await tester.pumpApp(
          buildTile(
            status: AttendanceStatus.late,
            notes: 'Stau auf der A1',
          ),
        );

        final noteText = tester.widget<Text>(
          find.text('Stau auf der A1'),
        );
        expect(noteText.style?.fontStyle, FontStyle.italic);
      });
    });

    group('basic rendering', () {
      widgetTest('shows person name', (tester) async {
        await tester.pumpApp(buildTile());

        expect(find.text('Max Mustermann'), findsOneWidget);
      });

      widgetTest('does not show group name', (tester) async {
        final personWithGroup = TestFactories.createPerson(
          id: 1,
          firstName: 'Max',
          lastName: 'Mustermann',
        );
        // Person model has groupName but tile should not display it
        await tester.pumpApp(
          Scaffold(
            body: AttendancePersonTile(
              person: personWithGroup,
              status: AttendanceStatus.present,
              notes: null,
              availableStatuses: AttendanceStatus.values,
              onStatusChanged: (_) {},
              onNoteChanged: (_) {},
              onShowModifierInfo: () {},
              onRemoveFromAttendance: () {},
            ),
          ),
        );

        // Only name should be shown, no subtitle when no notes
        expect(find.text('Max Mustermann'), findsOneWidget);
        // No second text line at all
        final column = tester.widget<Column>(find.byType(Column).first);
        final textChildren = column.children.whereType<Text>().toList();
        expect(textChildren.length, 1); // Only the name
      });
    });
  });
}
