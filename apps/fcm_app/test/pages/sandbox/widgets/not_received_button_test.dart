import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/domains/sandbox/entities/notification_send_exception.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/sandbox/sandbox_view.dart';
import 'package:fcm_app/pages/sandbox/widgets/not_received_button.dart';
import 'package:fcm_app/pages/sandbox/widgets/send_result_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../fakes/fake_notification_sender.dart';
import '../../../fakes/fake_run_scheduler.dart';
import '../../../fakes/in_memory_active_run_store.dart';
import '../../../fakes/recording_push_telemetry.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late FakeNotificationSender sender;
  late RecordingPushTelemetry reporter;
  late SandboxCubit controller;

  void build({NotificationSendException? failure}) {
    sender = FakeNotificationSender(failure: failure);
    reporter = RecordingPushTelemetry();
    controller = SandboxCubit(
      sender: sender,
      token: () => 'device-token',
      telemetry: reporter,
      startRun: StartRun(
        scheduler: FakeRunScheduler(),
        active: InMemoryActiveRunStore(),
      ),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: controller,
            child: const SandboxView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  /// The pressable part of the button, scoped so a [TextButton] belonging to the
  /// payload form cannot stand in for it.
  Finder pressable() => find.descendant(
    of: find.byType(NotReceivedButton),
    matching: find.byType(TextButton),
  );

  VoidCallback? onPressed(WidgetTester tester) =>
      tester.widget<TextButton>(pressable()).onPressed;

  Future<void> report(WidgetTester tester) async {
    // `warnIfMissed` is off because this is deliberately pressed again after it
    // has been disabled, and a disabled button reports no hit.
    await tester.tap(pressable(), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  List<String> traceIdsSent() => [
    for (final response in sender.responses) response.traceId,
  ];

  tearDown(() => controller.close());

  testWidgets('appears only after a send', (tester) async {
    // Before a send there is no trace id to report against.
    build();
    await pump(tester);

    // A positive control, so "no button" below means it was withheld rather than
    // that nothing rendered.
    expect(find.byType(FilledButton), findsOne);
    expect(find.byType(NotReceivedButton), findsNothing);

    await send(tester);

    expect(find.byType(NotReceivedButton), findsOne);
  });

  testWidgets('sits with the result rather than beside Send', (tester) async {
    // It reports against *that send's* trace id, so it belongs to the outcome —
    // confusing it with Send would cost a push nobody meant to send.
    build();
    await pump(tester);
    await send(tester);

    expect(
      find.descendant(
        of: find.byType(SendResultCard),
        matching: find.byType(NotReceivedButton),
      ),
      findsOne,
    );
    expect(
      find.byType(FilledButton),
      findsOne,
      reason: 'Send stays the only filled button on the page',
    );
  });

  testWidgets('records not_received against the sent trace id, then flushes', (
    tester,
  ) async {
    build();
    await pump(tester);
    await send(tester);

    await report(tester);

    final recorded = reporter.recorded.single;
    expect(recorded.type, TelemetryEventType.notReceived);
    expect(recorded.traceId, traceIdsSent().single);
    expect(
      recorded.scenarioId,
      controller.state.selectedScenario!.id,
      reason: 'the matrix groups not-received by scenario',
    );
    // Record *then* flush: the value stored at the flush proves the flush carried
    // the event rather than running before it was recorded.
    expect(reporter.recordedAtFlush, [1]);
  });

  testWidgets('cannot be pressed twice for one send', (tester) async {
    // Two rows for one message would inflate the only count a human produces.
    build();
    await pump(tester);
    await send(tester);

    // Pressable to begin with, or "one press per send" would be satisfied by a
    // button nobody could press at all.
    expect(onPressed(tester), isNotNull);
    expect(find.text('It never arrived'), findsOne);

    await report(tester);

    expect(onPressed(tester), isNull);
    // It says so rather than going quiet, or the user cannot tell a report that
    // landed from a button that ignored them.
    expect(find.text('It never arrived'), findsNothing);
    expect(find.textContaining('Reported'), findsOne);

    await report(tester);

    expect(reporter.recorded, hasLength(1));
    expect(reporter.flushes, 1);
  });

  testWidgets('a second send of the same scenario can be reported again', (
    tester,
  ) async {
    // A different message: a stale "already reported" would lose a real report.
    build();
    await pump(tester);
    await send(tester);
    await report(tester);

    await send(tester);

    expect(onPressed(tester), isNotNull);

    await report(tester);

    expect(
      traceIdsSent().toSet(),
      hasLength(2),
      reason: 'two sends with one trace id would let the wrong id pass',
    );
    final reportedIds = [for (final event in reporter.recorded) event.traceId];
    expect(reportedIds, traceIdsSent());
  });

  testWidgets('offers nothing to report when the send failed', (tester) async {
    // No response means no trace id, and a report against a message that never
    // left would show up as a delivery failure.
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);
    await send(tester);

    expect(find.text('The API is unreachable'), findsOne);
    expect(find.byType(NotReceivedButton), findsNothing);
  });

  testWidgets('offers nothing to report for a validated send', (tester) async {
    // The API records `sent` for a validate-only send too, so a `not_received`
    // beside it is indistinguishable from a genuine drop.
    build();
    await pump(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await send(tester);

    expect(
      find.textContaining('Validated'),
      findsOne,
      reason: 'a send did happen, so this is not "no send yet"',
    );
    expect(find.byType(NotReceivedButton), findsNothing);
  });

  testWidgets('forgets a report when the trace id changes under it', (
    tester,
  ) async {
    // Nothing guarantees a `SandboxSending` frame between two sends — in the test
    // above there is none, and the element is updated in place — so the reset has to
    // be the button's own business. Removing `didUpdateWidget` fails this and the
    // two-sends test above.
    //
    // Built without a page, so the shared `tearDown` has one of its own to dispose.
    build();
    final reported = <String>[];
    Future<void> pumpFor(String traceId) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotReceivedButton(
            traceId: traceId,
            onNotReceived: (id) async => reported.add(id),
          ),
        ),
      ),
    );

    await pumpFor('tr-7');
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await pumpFor('tr-8');

    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(reported, ['tr-7', 'tr-8']);
  });
}
