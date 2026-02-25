import 'package:attendix/shared/widgets/display/avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  widgetTestGroup('Avatar', () {
    group('initials display', () {
      widgetTest('shows initials when no image URL provided', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Max',
            lastName: 'Mustermann',
          ),
        );

        expect(find.text('MM'), findsOneWidget);
      });

      widgetTest('shows initials when image URL is empty', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Anna',
            lastName: 'Schmidt',
            imageUrl: '',
          ),
        );

        expect(find.text('AS'), findsOneWidget);
      });

      widgetTest('calculates initials correctly from first letters',
          (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'hans',
            lastName: 'peter',
          ),
        );

        // Should be uppercase
        expect(find.text('HP'), findsOneWidget);
      });

      widgetTest('handles empty firstName gracefully', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: '',
            lastName: 'Müller',
          ),
        );

        expect(find.text('M'), findsOneWidget);
      });

      widgetTest('handles empty lastName gracefully', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Lisa',
            lastName: '',
          ),
        );

        expect(find.text('L'), findsOneWidget);
      });

      widgetTest('handles both names empty', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: '',
            lastName: '',
          ),
        );

        // Should show empty string in CircleAvatar
        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });

    group('size parameter', () {
      widgetTest('default size is 40', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
          ),
        );

        final circleAvatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(circleAvatar.radius, 20); // size / 2
      });

      widgetTest('respects custom size parameter', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
            size: 60,
          ),
        );

        final circleAvatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(circleAvatar.radius, 30); // 60 / 2
      });

      widgetTest('adjusts font size based on avatar size', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
            size: 100,
          ),
        );

        final text = tester.widget<Text>(find.text('TU'));
        expect(text.style?.fontSize, 40); // size * 0.4
      });
    });

    group('image display', () {
      widgetTest('uses CachedNetworkImage when URL provided', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
            imageUrl: 'https://example.com/image.jpg',
          ),
        );

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      widgetTest('shows initials as placeholder while image loads',
          (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
            imageUrl: 'https://example.com/image.jpg',
          ),
        );

        // CachedNetworkImage will show placeholder initially
        // which should be the initials avatar
        await tester.pump();
        expect(find.text('TU'), findsOneWidget);
      });
    });

    group('styling', () {
      widgetTest('uses CircleAvatar widget', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      widgetTest('initials text is bold', (tester) async {
        await tester.pumpApp(
          const Avatar(
            firstName: 'Test',
            lastName: 'User',
          ),
        );

        final text = tester.widget<Text>(find.text('TU'));
        expect(text.style?.fontWeight, FontWeight.bold);
      });
    });
  });
}
