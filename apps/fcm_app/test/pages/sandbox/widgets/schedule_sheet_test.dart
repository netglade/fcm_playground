import 'package:fcm_app/pages/sandbox/widgets/schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  late ScheduleChoice? chosen;

  Future<void> open(
    WidgetTester tester, {
    int initialDelaySeconds = 20,
    bool withSpacing = false,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => chosen = await showScheduleSheet(
            context,
            initialDelaySeconds: initialDelaySeconds,
            withSpacing: withSpacing,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() => chosen = null);

  testWidgets('starts on the delay the scenario asked for', (tester) async {
    await open(tester, initialDelaySeconds: 30);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(chosen?.delaySeconds, 30);
  });

  testWidgets('falls back to 30 s where a scenario names none', (tester) async {
    await open(tester, initialDelaySeconds: 0);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(chosen?.delaySeconds, 30);
  });

  testWidgets('takes another preset', (tester) async {
    await open(tester);

    await tester.tap(find.text('60 s'));
    await tester.pump();
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(chosen?.delaySeconds, 60);
  });

  testWidgets('offers no spacing for a single send', (tester) async {
    await open(tester);

    expect(find.textContaining('Spacing'), findsNothing);
  });

  testWidgets('offers spacing for a batch, and reports it', (tester) async {
    await open(tester, withSpacing: true);

    expect(find.textContaining('Spacing'), findsOneWidget);
    await tester.tap(find.text('5 s'));
    await tester.pump();
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(chosen?.spacingSeconds, 5);
  });

  testWidgets('answers null when dismissed', (tester) async {
    await open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(chosen, isNull);
  });
}
