import 'package:attendix/core/constants/enums.dart';
import 'package:attendix/features/attendance/presentation/widgets/attendance_detail/attendance_status_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../factories/test_factories.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  widgetTestGroup('AttendanceStatusBar', () {
    group('statistics calculation', () {
      widgetTest('shows correct counts for active persons only', (tester) async {
        // Arrange: 3 active persons, each with a different status
        final persons = [
          TestFactories.createPerson(id: 1, firstName: 'Active', lastName: 'One'),
          TestFactories.createPerson(id: 2, firstName: 'Active', lastName: 'Two'),
          TestFactories.createPerson(id: 3, firstName: 'Active', lastName: 'Three'),
        ];

        final localStatuses = <int, AttendanceStatus>{
          1: AttendanceStatus.present,
          2: AttendanceStatus.excused,
          3: AttendanceStatus.neutral, // Open
        };

        // Act
        await tester.pumpApp(
          AttendanceStatusBar(
            persons: persons,
            localStatuses: localStatuses,
          ),
        );

        // Assert: Should show 1 present, 1 excused, 0 absent, 1 open
        expect(find.text('1'), findsNWidgets(3)); // present=1, excused=1, open=1
        expect(find.text('0'), findsOneWidget); // absent=0
        expect(find.text('33%'), findsOneWidget); // 1/3 = 33%
      });

      widgetTest('excludes paused persons from statistics even if they have status in localStatuses', (tester) async {
        // Arrange: 2 active persons + statuses for 3 (including 1 paused person not in persons list)
        final persons = [
          TestFactories.createPerson(id: 1, firstName: 'Active', lastName: 'One'),
          TestFactories.createPerson(id: 2, firstName: 'Active', lastName: 'Two'),
          // Person 3 is paused and NOT in the persons list
        ];

        // localStatuses contains status for all 3 persons (including paused person id=3)
        final localStatuses = <int, AttendanceStatus>{
          1: AttendanceStatus.present,
          2: AttendanceStatus.present,
          3: AttendanceStatus.neutral, // This is a paused person - should NOT be counted as "Offen"
        };

        // Act
        await tester.pumpApp(
          AttendanceStatusBar(
            persons: persons,
            localStatuses: localStatuses,
          ),
        );

        // Assert: Should show 2 present, 0 excused, 0 absent, 0 open (NOT 1 open!)
        // The paused person (id=3) should not be counted in statistics
        expect(find.text('Anwesend'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // present=2

        // Critical assertion: "Offen" should be 0, not 1
        // Find the "Offen" label and check its value
        expect(find.text('Offen'), findsOneWidget);

        // The value next to "Offen" should be 0
        // Since localStatuses has 3 entries but persons only has 2,
        // the neutral status for person 3 should NOT be counted
        //
        // BUG CASE: If the bug exists, we'll see "1" for "Offen" instead of "0"
        // because localStatuses.values counts all entries including paused person
        //
        // Expected: excused=0, absent=0, open=0 → three "0"s
        // Bug: excused=0, absent=0, open=1 → only two "0"s
        expect(find.text('0'), findsNWidgets(3)); // excused=0, absent=0, open=0

        expect(find.text('100%'), findsOneWidget); // 2/2 = 100%
      });

      widgetTest('handles multiple paused persons correctly', (tester) async {
        // Arrange: 3 active persons, but localStatuses has 5 entries (2 paused)
        final persons = [
          TestFactories.createPerson(id: 1, firstName: 'Active', lastName: 'One'),
          TestFactories.createPerson(id: 2, firstName: 'Active', lastName: 'Two'),
          TestFactories.createPerson(id: 3, firstName: 'Active', lastName: 'Three'),
        ];

        // localStatuses contains status for 5 persons (2 paused not in persons list)
        final localStatuses = <int, AttendanceStatus>{
          1: AttendanceStatus.present,
          2: AttendanceStatus.excused,
          3: AttendanceStatus.absent,
          4: AttendanceStatus.neutral, // Paused person - should NOT count
          5: AttendanceStatus.neutral, // Another paused person - should NOT count
        };

        // Act
        await tester.pumpApp(
          AttendanceStatusBar(
            persons: persons,
            localStatuses: localStatuses,
          ),
        );

        // Assert: Should count only active persons
        // present=1, excused=1, absent=1, open=0 (NOT 2!)
        expect(find.text('Anwesend'), findsOneWidget);
        expect(find.text('Entsch.'), findsOneWidget);
        expect(find.text('Abwesend'), findsOneWidget);
        expect(find.text('Offen'), findsOneWidget);

        // Each count should be 1 (present, excused, absent)
        expect(find.text('1'), findsNWidgets(3));

        // The key assertion: "Offen" should be 0, not 2
        // Because persons 4 and 5 are not in the persons list (they're paused)
        expect(find.text('0'), findsOneWidget); // Only open=0

        expect(find.text('33%'), findsOneWidget); // 1/3 = 33%
      });

      widgetTest('counts late statuses as present', (tester) async {
        final persons = [
          TestFactories.createPerson(id: 1, firstName: 'Active', lastName: 'One'),
          TestFactories.createPerson(id: 2, firstName: 'Active', lastName: 'Two'),
          TestFactories.createPerson(id: 3, firstName: 'Active', lastName: 'Three'),
        ];

        final localStatuses = <int, AttendanceStatus>{
          1: AttendanceStatus.present,
          2: AttendanceStatus.late,
          3: AttendanceStatus.lateExcused,
        };

        await tester.pumpApp(
          AttendanceStatusBar(
            persons: persons,
            localStatuses: localStatuses,
          ),
        );

        // All 3 should count as present (present + late + lateExcused)
        expect(find.text('3'), findsOneWidget); // present=3
        expect(find.text('100%'), findsOneWidget);
      });

      widgetTest('handles empty persons list', (tester) async {
        await tester.pumpApp(
          const AttendanceStatusBar(
            persons: [],
            localStatuses: {},
          ),
        );

        // All counts should be 0
        expect(find.text('0'), findsNWidgets(4)); // present, excused, absent, open all 0
        expect(find.text('0%'), findsOneWidget); // 0/0 = 0%
      });
    });

    group('UI display', () {
      widgetTest('displays all status labels', (tester) async {
        await tester.pumpApp(
          const AttendanceStatusBar(
            persons: [],
            localStatuses: {},
          ),
        );

        expect(find.text('Anwesend'), findsOneWidget);
        expect(find.text('Entsch.'), findsOneWidget);
        expect(find.text('Abwesend'), findsOneWidget);
        expect(find.text('Offen'), findsOneWidget);
      });
    });
  });
}
