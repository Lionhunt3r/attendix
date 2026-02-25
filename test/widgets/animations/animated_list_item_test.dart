import 'package:attendix/shared/widgets/animations/animated_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  widgetTestGroup('AnimatedListItem', () {
    group('animation behavior', () {
      widgetTest('starts with opacity 0 for animated items', (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 0,
            child: const Text('Test'),
          ),
        );

        // Initially should be invisible (opacity 0)
        final fadeTransition = tester.widget<FadeTransition>(
          find.byType(FadeTransition),
        );
        expect(fadeTransition.opacity.value, 0.0);

        // Clean up timers
        await tester.pumpAndSettle();
      });

      widgetTest('animates to full opacity after delay', (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 0,
            delay: const Duration(milliseconds: 50),
            duration: const Duration(milliseconds: 100),
            child: const Text('Test'),
          ),
        );

        // After animation completes
        await tester.pumpAndSettle();

        final fadeTransition = tester.widget<FadeTransition>(
          find.byType(FadeTransition),
        );
        expect(fadeTransition.opacity.value, 1.0);
      });

      widgetTest('calculates stagger delay based on index', (tester) async {
        await tester.pumpApp(
          Column(
            children: [
              AnimatedListItem(
                index: 0,
                delay: const Duration(milliseconds: 10),
                duration: const Duration(milliseconds: 50),
                child: const Text('Item 0'),
              ),
              AnimatedListItem(
                index: 2,
                delay: const Duration(milliseconds: 10),
                duration: const Duration(milliseconds: 50),
                child: const Text('Item 2'),
              ),
            ],
          ),
        );

        // Verify both items have FadeTransition (they animate)
        expect(
          find.descendant(
            of: find.byType(AnimatedListItem),
            matching: find.byType(FadeTransition),
          ),
          findsNWidgets(2),
        );

        // Let animations complete
        await tester.pumpAndSettle();

        // After completion, both should be fully visible
        final item0 = tester.widget<FadeTransition>(
          find.ancestor(
            of: find.text('Item 0'),
            matching: find.byType(FadeTransition),
          ),
        );
        final item2 = tester.widget<FadeTransition>(
          find.ancestor(
            of: find.text('Item 2'),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(item0.opacity.value, 1.0);
        expect(item2.opacity.value, 1.0);
      });
    });

    group('maxStaggerIndex optimization', () {
      widgetTest('items beyond maxStaggerIndex skip animation', (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 15,
            maxStaggerIndex: 10,
            child: const Text('Beyond max'),
          ),
        );

        // Should not have FadeTransition wrapper
        expect(find.byType(FadeTransition), findsNothing);
        // But should still show the child
        expect(find.text('Beyond max'), findsOneWidget);
      });

      widgetTest('items within maxStaggerIndex animate', (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 5,
            maxStaggerIndex: 10,
            delay: const Duration(milliseconds: 10),
            duration: const Duration(milliseconds: 50),
            child: const Text('Within max'),
          ),
        );

        // Should have FadeTransition wrapper
        expect(find.byType(FadeTransition), findsOneWidget);

        // Clean up - wait for stagger delay (5*10=50ms) + duration (50ms)
        await tester.pumpAndSettle();
      });

      widgetTest('item at exactly maxStaggerIndex skips animation',
          (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 10,
            maxStaggerIndex: 10,
            child: const Text('At max'),
          ),
        );

        // index >= maxStaggerIndex means no animation
        expect(find.byType(FadeTransition), findsNothing);
      });
    });

    group('slide animation', () {
      widgetTest('uses SlideTransition for vertical movement', (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 0,
            child: const Text('Test'),
          ),
        );

        expect(find.byType(SlideTransition), findsOneWidget);

        // Clean up
        await tester.pumpAndSettle();
      });

      widgetTest('respects slideOffset parameter', (tester) async {
        await tester.pumpApp(
          AnimatedListItem(
            index: 0,
            slideOffset: 0.2,
            child: const Text('Test'),
          ),
        );

        final slideTransition = tester.widget<SlideTransition>(
          find.byType(SlideTransition),
        );
        // Initial offset should be (0, 0.2)
        expect(slideTransition.position.value.dy, 0.2);

        // Clean up
        await tester.pumpAndSettle();
      });
    });
  });

  widgetTestGroup('TapScale', () {
    group('tap interaction', () {
      widgetTest('calls onTap callback when tapped', (tester) async {
        var tapped = false;

        await tester.pumpApp(
          TapScale(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        );

        await tester.tap(find.text('Tap me'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      widgetTest('does not respond to tap when onTap is null', (tester) async {
        await tester.pumpApp(
          const TapScale(
            onTap: null,
            child: Text('Disabled'),
          ),
        );

        // Should still render but not react to taps
        expect(find.text('Disabled'), findsOneWidget);
      });

      widgetTest('scales down on tap down', (tester) async {
        await tester.pumpApp(
          TapScale(
            onTap: () {},
            scale: 0.95,
            child: const Text('Tap me'),
          ),
        );

        // Start tap gesture
        final gesture =
            await tester.startGesture(tester.getCenter(find.text('Tap me')));
        await tester.pumpAndSettle();

        final scaleTransition = tester.widget<ScaleTransition>(
          find.byType(ScaleTransition),
        );
        expect(scaleTransition.scale.value, 0.95);

        // Release gesture
        await gesture.up();
        await tester.pumpAndSettle();
      });

      widgetTest('returns to normal scale on tap up', (tester) async {
        await tester.pumpApp(
          TapScale(
            onTap: () {},
            child: const Text('Tap me'),
          ),
        );

        // Complete a tap
        await tester.tap(find.text('Tap me'));
        await tester.pumpAndSettle();

        final scaleTransition = tester.widget<ScaleTransition>(
          find.byType(ScaleTransition),
        );
        expect(scaleTransition.scale.value, 1.0);
      });

      widgetTest('returns to normal scale on tap cancel', (tester) async {
        await tester.pumpApp(
          TapScale(
            onTap: () {},
            child: const Text('Tap me'),
          ),
        );

        // Start gesture then cancel
        final gesture =
            await tester.startGesture(tester.getCenter(find.text('Tap me')));
        await tester.pump();
        await gesture.cancel();
        await tester.pumpAndSettle();

        final scaleTransition = tester.widget<ScaleTransition>(
          find.byType(ScaleTransition),
        );
        expect(scaleTransition.scale.value, 1.0);
      });
    });

    group('scale configuration', () {
      widgetTest('respects custom scale parameter', (tester) async {
        await tester.pumpApp(
          TapScale(
            onTap: () {},
            scale: 0.8,
            child: const Text('Tap me'),
          ),
        );

        final gesture =
            await tester.startGesture(tester.getCenter(find.text('Tap me')));
        await tester.pumpAndSettle();

        final scaleTransition = tester.widget<ScaleTransition>(
          find.byType(ScaleTransition),
        );
        expect(scaleTransition.scale.value, 0.8);

        await gesture.up();
        await tester.pumpAndSettle();
      });

      widgetTest('default scale is 0.97', (tester) async {
        await tester.pumpApp(
          TapScale(
            onTap: () {},
            child: const Text('Tap me'),
          ),
        );

        final gesture =
            await tester.startGesture(tester.getCenter(find.text('Tap me')));
        await tester.pumpAndSettle();

        final scaleTransition = tester.widget<ScaleTransition>(
          find.byType(ScaleTransition),
        );
        expect(scaleTransition.scale.value, 0.97);

        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  });

  widgetTestGroup('FadeIn', () {
    widgetTest('starts with opacity 0', (tester) async {
      await tester.pumpApp(
        const FadeIn(
          child: Text('Fade me'),
        ),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 0.0);

      // Clean up
      await tester.pumpAndSettle();
    });

    widgetTest('animates to full opacity', (tester) async {
      await tester.pumpApp(
        const FadeIn(
          duration: Duration(milliseconds: 100),
          child: Text('Fade me'),
        ),
      );

      await tester.pumpAndSettle();

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 1.0);
    });

    widgetTest('respects delay parameter', (tester) async {
      await tester.pumpApp(
        const FadeIn(
          delay: Duration(milliseconds: 200),
          duration: Duration(milliseconds: 100),
          child: Text('Delayed'),
        ),
      );

      // After 100ms, animation hasn't started yet due to delay
      await tester.pump(const Duration(milliseconds: 100));
      var fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 0.0);

      // After full delay + animation
      await tester.pumpAndSettle();
      fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 1.0);
    });
  });

  widgetTestGroup('SlideUp', () {
    widgetTest('starts with vertical offset', (tester) async {
      await tester.pumpApp(
        const SlideUp(
          offset: 0.1,
          child: Text('Slide me'),
        ),
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value.dy, 0.1);

      // Clean up
      await tester.pumpAndSettle();
    });

    widgetTest('animates to zero offset', (tester) async {
      await tester.pumpApp(
        const SlideUp(
          duration: Duration(milliseconds: 100),
          child: Text('Slide me'),
        ),
      );

      await tester.pumpAndSettle();

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value.dy, 0.0);
    });

    widgetTest('includes fade animation', (tester) async {
      await tester.pumpApp(
        const SlideUp(
          duration: Duration(milliseconds: 100),
          child: Text('Slide me'),
        ),
      );

      // SlideUp wraps in both FadeTransition and SlideTransition
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Clean up all timers
      await tester.pumpAndSettle();
    });

    widgetTest('respects delay parameter', (tester) async {
      await tester.pumpApp(
        const SlideUp(
          delay: Duration(milliseconds: 200),
          duration: Duration(milliseconds: 100),
          offset: 0.2,
          child: Text('Delayed'),
        ),
      );

      // After 100ms, still at initial offset
      await tester.pump(const Duration(milliseconds: 100));
      var slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value.dy, 0.2);

      // After full delay + animation
      await tester.pumpAndSettle();
      slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value.dy, 0.0);
    });
  });
}
