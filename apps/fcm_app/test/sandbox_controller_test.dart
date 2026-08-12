import 'dart:convert';

import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/sandbox/sandbox_send_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

void main() {
  late FakeNotificationSender sender;

  SandboxController controllerWith({
    String? token = 'device-token',
    FakeNotificationSender? withSender,
  }) {
    sender = withSender ?? FakeNotificationSender();

    return SandboxController(sender: sender, token: () => token);
  }

  group('SandboxController', () {
    test('opens on the first scenario, so the page is sendable at once', () {
      final controller = controllerWith();

      expect(controller.selectedScenario?.id, scenarioGallery.first.id);
      expect(controller.parseError, isNull);
      expect(controller.parsedMessage, isNotNull);
      expect(controller.canSend, isTrue);
    });

    test('writes the template into the editor as indented JSON', () {
      final controller = controllerWith();

      expect(controller.payloadText, contains('\n'));
      expect(
        jsonDecode(controller.payloadText),
        scenarioGallery.first.payloadTemplate,
      );
    });

    test('replaces the editor when another scenario is applied', () {
      final controller = controllerWith();
      final dataOnly = scenarioGallery.firstWhere(
        (scenario) => scenario.id == 'data_only',
      );

      controller.applyScenario(dataOnly);

      expect(controller.selectedScenario?.id, 'data_only');
      expect(jsonDecode(controller.payloadText), dataOnly.payloadTemplate);
    });

    test('bumps the revision on a scenario so the field can be rebuilt', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.applyScenario(scenarioGallery.last);

      expect(controller.scenarioRevision, greaterThan(before));
    });

    test('does not bump the revision on an ordinary edit', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.editPayload('{"data": {"a": "b"}}');

      expect(controller.scenarioRevision, before);
    });

    test('reports text that is not JSON and blocks Send', () {
      final controller = controllerWith();

      controller.editPayload('{not json');

      expect(controller.parseError, isNotNull);
      expect(controller.parsedMessage, isNull);
      expect(controller.canSend, isFalse);
    });

    test('reports an unknown field with its path', () {
      final controller = controllerWith();

      controller.editPayload('{"notification": {"titel": "typo"}}');

      expect(controller.parseError, contains('unknown field "titel"'));
    });

    test('reports a template that sets its own target', () {
      final controller = controllerWith();

      controller.editPayload('{"token": "mine"}');

      expect(
        controller.parseError,
        contains('the server sets the delivery target'),
      );
    });

    test('accepts a payload that is valid again after being broken', () {
      final controller = controllerWith()..editPayload('{oops');

      controller.editPayload('{"data": {"a": "b"}}');

      expect(controller.parseError, isNull);
      expect(controller.parsedMessage?.data, {'a': 'b'});
    });

    test('blocks Send with a reason when there is no token', () {
      final controller = controllerWith(token: null);

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('token'));
    });

    test('sends the parsed message with the device token', () async {
      final controller = controllerWith()
        ..editPayload('{"data": {"event": "manual"}}');

      await controller.send();

      expect(sender.sent.single.token, 'device-token');
      expect(sender.sent.single.message.data, {'event': 'manual'});
      expect(sender.sent.single.validateOnly, isFalse);
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

    test(
      'refuses to send unparseable text, without calling the sender',
      () async {
        final controller = controllerWith()..editPayload('{oops');

        await controller.send();

        expect(sender.sent, isEmpty);
      },
    );

    test('lands on Failed and keeps the text when the send fails', () async {
      final controller = controllerWith(
        withSender: FakeNotificationSender(
          failure: const NotificationSendException('The API is unreachable'),
        ),
      )..editPayload('{"data": {"kept": "yes"}}');

      await controller.send();

      expect(controller.state, isA<SandboxFailed>());
      expect(controller.payloadText, contains('kept'));
    });
  });
}
