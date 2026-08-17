import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_cubit.dart';
import 'package:fcm_app/sandbox/sandbox_send_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fake_notification_sender.dart';

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
    final cubit = SandboxCubit(sender: sender, token: () => token);
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

      // A target left behind by the previous scenario would broadcast the next
      // one, which is the failure `FcmMessage` refuses to make possible.
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
      // The behaviour the whole form exists for: a scenario is a starting point,
      // not the payload. Asserted on the posted JSON, because that is the only
      // place where a field lost between the input and the wire would show.
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
      // owned by AndroidNotificationForm, whose notification never reaches the
      // root, so a listener on the root form alone would miss this entirely.
      //
      // A valid colour on purpose: it moves none of the five scalars in
      // SandboxState, so this is also what pins the state's identity equality.
      // Were the state value-equal, `Cubit.emit` would drop this edit and the
      // form controls — stateless readers of `input.value` — would never redraw.
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
      // Eleven models, one listener each. A listener left behind emits on a
      // closed cubit, which throws — but ChangeNotifier catches what a listener
      // throws and reports it to FlutterError instead of rethrowing, so the
      // reported errors are what has to be watched rather than the call.
      final cubit = SandboxCubit(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
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
}
