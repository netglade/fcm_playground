import 'package:fcm_app/domains/runs/run_scheduler_exception.dart';
import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/domains/sandbox/notification_send_exception.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_send_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../fakes/fake_notification_sender.dart';
import '../../../fakes/fake_run_scheduler.dart';
import '../../../fakes/in_memory_active_run_store.dart';

void main() {
  // The cubit builds a GladeModel in its constructor, so the library has to be
  // initialized before the first one is created.
  setUpAll(GladeForms.initialize);

  late FakeNotificationSender sender;

  SandboxCubit cubitWith({
    String? token = 'device-token',
    FakeNotificationSender? withSender,
  }) {
    sender = withSender ?? FakeNotificationSender();
    final cubit = SandboxCubit(
      sender: sender,
      token: () => token,
      startRun: StartRun(
        scheduler: FakeRunScheduler(),
        active: InMemoryActiveRunStore(),
      ),
    );
    addTearDown(cubit.close);

    return cubit;
  }

  group('SandboxCubit', () {
    test('opens on the first scenario, so the page is sendable at once', () {
      final cubit = cubitWith();

      expect(cubit.state.selectedScenario?.id, scenarioGallery.first.id);
      expect(cubit.form.isValid, isTrue);
      expect(cubit.canSend, isTrue);
    });

    test('reads the first scenario into the form', () {
      final cubit = cubitWith();

      expect(
        cubit.form.toModel(),
        FcmMessage.fromJson(scenarioGallery.first.payloadTemplate),
      );
    });

    test('replaces the fields when another scenario is applied', () {
      final cubit = cubitWith();
      final dataOnly = scenarioGallery.firstWhere(
        (scenario) => scenario.id == 'a2_data_only',
      );

      cubit.applyScenario(dataOnly);

      expect(cubit.state.selectedScenario?.id, 'a2_data_only');
      expect(
        cubit.form.toModel(),
        FcmMessage.fromJson(dataOnly.payloadTemplate),
      );
      // a2_data_only has no notification block, so the first scenario's title
      // must be gone rather than merged into the new payload.
      expect(cubit.form.notification.title.value, isEmpty);
    });

    test('blocks Send with an actionable reason when a field is invalid', () {
      final cubit = cubitWith();

      cubit.form.android.ttl.updateValue('later');

      expect(cubit.form.isValid, isFalse);
      expect(cubit.canSend, isFalse);
      expect(cubit.sendBlockedReason, contains('invalid'));
    });

    test(
      'refuses to send an invalid form, without calling the sender',
      () async {
        final cubit = cubitWith();

        cubit.form.android.ttl.updateValue('later');
        await cubit.send();

        expect(sender.sent, isEmpty);
      },
    );

    test('blocks Send with a reason when there is no token', () {
      final cubit = cubitWith(token: null);

      expect(cubit.canSend, isFalse);
      expect(cubit.sendBlockedReason, contains('token'));
    });

    test('sends the form\'s message with the device token', () async {
      final cubit = cubitWith();

      await cubit.send();

      expect(sender.sent.single.target, const TokenTarget('device-token'));
      expect(sender.sent.single.message, cubit.form.toModel());
      expect(sender.sent.single.validateOnly, isFalse);
    });

    test('sends to this device when no target is chosen', () async {
      final cubit = cubitWith();

      await cubit.send();

      expect(cubit.state.target, isNull);
      expect(sender.sent.single.target, const TokenTarget('device-token'));
    });

    test('sends to the chosen target instead of this device', () async {
      final cubit = cubitWith();

      cubit.setTarget(const TopicTarget('news'));
      await cubit.send();

      expect(sender.sent.single.target, const TopicTarget('news'));
    });

    test('takes the target from an applied scenario, and drops it again', () {
      final cubit = cubitWith();

      cubit.applyScenario(
        scenarioGallery.firstWhere((scenario) => scenario.id == 'j2_condition'),
      );

      expect(
        cubit.state.target,
        const ConditionTarget("'news' in topics && 'beta' in topics"),
      );

      cubit.applyScenario(
        scenarioGallery.firstWhere(
          (scenario) => scenario.id == 'a1_notification_only',
        ),
      );

      // A target left behind by the previous scenario would broadcast the next one.
      expect(cubit.state.target, isNull);
    });

    test('blocks Send with a reason when the chosen target is blank', () {
      final cubit = cubitWith()..setTarget(const TopicTarget(''));

      expect(cubit.canSend, isFalse);
      expect(cubit.sendBlockedReason, contains('delivery target'));
    });

    test('treats a whitespace-only target as blank', () {
      // The API's own reader rejects a blank target on `trim()`, so accepting
      // spaces here would only move the refusal to a 400.
      final cubit = cubitWith()..setTarget(const TokenTarget('   '));

      expect(cubit.canSend, isFalse);
      expect(cubit.sendBlockedReason, contains('delivery target'));
    });

    test(
      'refuses to send a blank target, without calling the sender',
      () async {
        final cubit = cubitWith()..setTarget(const ConditionTarget(''));

        await cubit.send();

        expect(sender.sent, isEmpty);
      },
    );

    test('sends what was edited after a scenario was applied', () async {
      // A scenario is a starting point, not the payload. Asserted on the posted
      // JSON, the only place a field lost between the input and the wire shows.
      final cubit = cubitWith();

      cubit.form.notification.title.updateValue('Edited by hand');
      cubit.form.android.notification.color.updateValue('#ff0000');
      await cubit.send();

      expect(sender.sent.single.message.toJson(), {
        'notification': {
          'title': 'Edited by hand',
          'body': 'Release 1.0.0 is ready.',
        },
        'android': {
          'notification': {'color': '#ff0000'},
        },
      });
    });

    test('sends validate_only when the flag is set', () async {
      final cubit = cubitWith()..setValidateOnly(true);

      await cubit.send();

      expect(sender.sent.single.validateOnly, isTrue);
      expect(cubit.state.validateOnly, isTrue);
    });

    test('lands on Sent with the response', () async {
      final cubit = cubitWith();

      await cubit.send();

      expect(cubit.state.sendState, isA<SandboxSent>());
      expect(
        (cubit.state.sendState as SandboxSent).response.messageId,
        FakeNotificationSender.response.messageId,
      );
    });

    test('lands on Failed and keeps the form\'s contents', () async {
      final cubit = cubitWith(
        withSender: FakeNotificationSender(
          failure: const NotificationSendException('The API is unreachable'),
        ),
      );

      cubit.form.data.updateValue({'kept': 'yes'});
      await cubit.send();

      expect(cubit.state.sendState, isA<SandboxFailed>());
      expect(cubit.form.data.value, {'kept': 'yes'});
    });

    test('drops a stale result when the payload changes', () async {
      final cubit = cubitWith();
      await cubit.send();
      expect(cubit.state.sendState, isA<SandboxSent>());

      cubit.form.notification.title.updateValue('Changed since');

      expect(cubit.state.sendState, isA<SandboxIdle>());
    });

    test('re-notifies for a change three levels down', () async {
      // What proves the allModels wiring is live: android.notification.color is
      // owned by AndroidNotificationForm, whose notification never reaches the root.
      //
      // A valid colour on purpose: it moves none of SandboxState's scalars, so this
      // also pins the state's identity equality — value equality would make
      // `Cubit.emit` drop the edit and the controls would never redraw.
      final cubit = cubitWith();
      var notifications = 0;
      final states = cubit.stream.listen((_) => notifications++);
      addTearDown(states.cancel);

      cubit.form.android.notification.color.updateValue('#123456');
      // `state` moves synchronously, but the stream delivers in a microtask.
      await Future<void>.delayed(Duration.zero);

      expect(notifications, greaterThan(0));
    });

    test('stops listening to every model on close', () async {
      // A listener left behind emits on a closed cubit, which throws — but
      // ChangeNotifier reports what a listener throws to FlutterError instead of
      // rethrowing, so the reported errors are what has to be watched.
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
        startRun: StartRun(
          scheduler: FakeRunScheduler(),
          active: InMemoryActiveRunStore(),
        ),
      );
      final form = cubit.form;
      await cubit.close();

      final reported = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      form.android.notification.color.updateValue('#123456');

      expect(reported, isEmpty);
    });
  });

  group('schedule', () {
    test('posts one item carrying the payload and the scenario', () async {
      final runs = FakeRunScheduler();
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
        startRun: StartRun(scheduler: runs, active: InMemoryActiveRunStore()),
      )..applyScenario(scenarioGallery.firstWhere((s) => s.id == 'b3_killed'));
      cubit.form.notification.title.updateValue('Killed-app probe');

      final run = await cubit.schedule(30);

      expect(run, isNotNull);
      final request = runs.scheduled.single;
      expect(request.delaySeconds, 30);
      expect(request.items.single.scenarioId, 'b3_killed');
      expect(request.items.single.target, const TokenTarget('device-token'));
      // The gap this test used to leave: it named "the payload" but never read it
      // back, so a message dropped between the form and the request would have
      // passed unnoticed.
      expect(request.items.single.message, cubit.form.toModel());
      expect(
        request.items.single.message.notification?.title,
        'Killed-app probe',
      );
    });

    test('reads the form at the press, not once the run comes back', () async {
      // Mirrors `send`'s own guarantee, and the comment in `schedule` that
      // makes it: the read has to happen before the request is handed to
      // the scheduler, or an edit made while the call is in flight would
      // travel instead of what was on screen at the press.
      final runs = FakeRunScheduler();
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
        startRun: StartRun(scheduler: runs, active: InMemoryActiveRunStore()),
      )..applyScenario(scenarioGallery.firstWhere((s) => s.id == 'b3_killed'));
      cubit.form.notification.title.updateValue('At the press');

      // Not awaited yet: `schedule` runs synchronously up to its first
      // `await`, so the read below happens either before this line
      // (correct) or after it (if it were moved past an `await`) — which
      // is exactly what this proves.
      final pending = cubit.schedule(30);
      cubit.form.notification.title.updateValue('After the press');
      await pending;

      expect(
        runs.scheduled.single.items.single.message.notification?.title,
        'At the press',
      );
    });

    test('remembers the run, so a killed app can reopen it', () async {
      final active = InMemoryActiveRunStore();
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
        startRun: StartRun(scheduler: FakeRunScheduler(), active: active),
      );

      await cubit.schedule(30);

      expect(await active.activeRunId(), 'run-1');
    });

    test('publishes the scheduled run so the card can name it', () async {
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
        startRun: StartRun(
          scheduler: FakeRunScheduler(),
          active: InMemoryActiveRunStore(),
        ),
      );

      await cubit.schedule(30);

      expect(cubit.state.sendState, isA<SandboxScheduled>());
    });

    test(
      'reports a refusal without pretending anything was scheduled',
      () async {
        final cubit = SandboxCubit(
          sender: FakeNotificationSender(),
          token: () => 'device-token',
          startRun: StartRun(
            scheduler: FakeRunScheduler(
              failure: const RunSchedulerException('Could not reach the API'),
            ),
            active: InMemoryActiveRunStore(),
          ),
        );

        expect(await cubit.schedule(30), isNull);
        expect(cubit.state.sendState, isA<SandboxFailed>());
      },
    );

    test('schedules nothing when there is nowhere to send', () async {
      final runs = FakeRunScheduler();
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => null,
        startRun: StartRun(scheduler: runs, active: InMemoryActiveRunStore()),
      );

      expect(await cubit.schedule(30), isNull);
      expect(runs.scheduled, isEmpty);
    });
  });
}
