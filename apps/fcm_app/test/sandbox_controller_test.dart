import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/sandbox/sandbox_send_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fake_notification_sender.dart';

void main() {
  // The controller builds a GladeModel in its constructor, so the library has
  // to be initialized before the first one is created.
  setUpAll(GladeForms.initialize);

  late FakeNotificationSender sender;

  SandboxController controllerWith({
    String? token = 'device-token',
    FakeNotificationSender? withSender,
  }) {
    sender = withSender ?? FakeNotificationSender();
    final controller = SandboxController(sender: sender, token: () => token);
    addTearDown(controller.dispose);

    return controller;
  }

  group('SandboxController', () {
    test('opens on the first scenario, so the page is sendable at once', () {
      final controller = controllerWith();

      expect(controller.selectedScenario?.id, scenarioGallery.first.id);
      expect(controller.form.isValid, isTrue);
      expect(controller.canSend, isTrue);
    });

    test('reads the first scenario into the form', () {
      final controller = controllerWith();

      expect(
        controller.form.toModel(),
        FcmMessage.fromJson(scenarioGallery.first.payloadTemplate),
      );
    });

    test('replaces the fields when another scenario is applied', () {
      final controller = controllerWith();
      final dataOnly = scenarioGallery.firstWhere(
        (scenario) => scenario.id == 'data_only',
      );

      controller.applyScenario(dataOnly);

      expect(controller.selectedScenario?.id, 'data_only');
      expect(
        controller.form.toModel(),
        FcmMessage.fromJson(dataOnly.payloadTemplate),
      );
      // data_only has no notification block, so the first scenario's title must
      // be gone rather than merged into the new payload.
      expect(controller.form.notification.title.value, isEmpty);
    });

    test('blocks Send with an actionable reason when a field is invalid', () {
      final controller = controllerWith();

      controller.form.android.ttl.updateValue('later');

      expect(controller.form.isValid, isFalse);
      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('invalid'));
    });

    test(
      'refuses to send an invalid form, without calling the sender',
      () async {
        final controller = controllerWith();

        controller.form.android.ttl.updateValue('later');
        await controller.send();

        expect(sender.sent, isEmpty);
      },
    );

    test('blocks Send with a reason when there is no token', () {
      final controller = controllerWith(token: null);

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('token'));
    });

    test('sends the form\'s message with the device token', () async {
      final controller = controllerWith();

      await controller.send();

      expect(sender.sent.single.token, 'device-token');
      expect(sender.sent.single.message, controller.form.toModel());
      expect(sender.sent.single.validateOnly, isFalse);
    });

    test('sends what was edited after a scenario was applied', () async {
      // The behaviour the whole form exists for: a scenario is a starting point,
      // not the payload. Asserted on the posted JSON, because that is the only
      // place where a field lost between the input and the wire would show.
      final controller = controllerWith();

      controller.form.notification.title.updateValue('Edited by hand');
      controller.form.android.notification.color.updateValue('#ff0000');
      await controller.send();

      expect(sender.sent.single.message.toJson(), {
        'notification': {
          'title': 'Edited by hand',
          'body': 'Release 1.0.0 is ready.',
          'image': 'https://picsum.photos/600/300',
        },
        'android': {
          'notification': {'color': '#ff0000'},
        },
      });
    });

    test('sends validate_only when the flag is set', () async {
      final controller = controllerWith()..setValidateOnly(true);

      await controller.send();

      expect(sender.sent.single.validateOnly, isTrue);
      expect(controller.validateOnly, isTrue);
    });

    test('lands on Sent with the response', () async {
      final controller = controllerWith();

      await controller.send();

      expect(controller.state, isA<SandboxSent>());
      expect(
        (controller.state as SandboxSent).response.messageId,
        FakeNotificationSender.response.messageId,
      );
    });

    test('lands on Failed and keeps the form\'s contents', () async {
      final controller = controllerWith(
        withSender: FakeNotificationSender(
          failure: const NotificationSendException('The API is unreachable'),
        ),
      );

      controller.form.data.updateValue({'kept': 'yes'});
      await controller.send();

      expect(controller.state, isA<SandboxFailed>());
      expect(controller.form.data.value, {'kept': 'yes'});
    });

    test('drops a stale result when the payload changes', () async {
      final controller = controllerWith();
      await controller.send();
      expect(controller.state, isA<SandboxSent>());

      controller.form.notification.title.updateValue('Changed since');

      expect(controller.state, isA<SandboxIdle>());
    });

    test('re-notifies for a change three levels down', () {
      // What proves the allModels wiring is live: android.notification.color is
      // owned by AndroidNotificationForm, whose notification never reaches the
      // root, so a listener on the root form alone would miss this entirely.
      final controller = controllerWith();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.form.android.notification.color.updateValue('#123456');

      expect(notifications, greaterThan(0));
    });

    test('stops listening to every model on dispose', () {
      // Eleven models, one listener each. An un-removed listener notifies a
      // disposed ChangeNotifier, which asserts — but ChangeNotifier catches what
      // a listener throws and reports it to FlutterError instead of rethrowing,
      // so the reported errors are what has to be watched rather than the call.
      final controller = SandboxController(
        sender: FakeNotificationSender(),
        token: () => 'device-token',
      );
      final form = controller.form;
      controller.dispose();

      final reported = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      form.android.notification.color.updateValue('#123456');

      expect(reported, isEmpty);
    });
  });
}
