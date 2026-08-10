import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

SandboxController _controller(
  FakeNotificationSender sender, {
  String? token = 'device-token',
}) => SandboxController(sender: sender, readToken: () => token);

void main() {
  group('SandboxController', () {
    test(
      'starts from the first gallery scenario, so the form is never blank',
      () {
        final controller = _controller(FakeNotificationSender());

        expect(controller.draft, notificationGallery.first.draft);
        expect(controller.problems, isEmpty);
      },
    );

    test('applying a scenario replaces the draft and bumps the generation', () {
      final controller = _controller(FakeNotificationSender());
      final before = controller.scenarioGeneration;

      controller.applyScenario(notificationGallery.last);

      expect(controller.draft, notificationGallery.last.draft);
      expect(controller.scenarioGeneration, greaterThan(before));
    });

    test(
      'editing the draft revalidates but leaves the generation alone, so the '
      'text fields are not reseeded mid-typing',
      () {
        final controller = _controller(FakeNotificationSender());
        final before = controller.scenarioGeneration;

        controller.editDraft(controller.draft.copyWith(title: ''));

        expect(controller.problems.map((p) => p.field), contains('title'));
        expect(controller.scenarioGeneration, before);
      },
    );

    test('cannot send an invalid draft', () {
      final controller = _controller(FakeNotificationSender());

      controller.editDraft(controller.draft.copyWith(title: '', body: ''));

      expect(controller.canSend, isFalse);
    });

    test('cannot send without a registration token', () {
      final controller = _controller(FakeNotificationSender(), token: null);

      expect(controller.canSend, isFalse);
    });

    test('sends the current draft with the current token', () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);

      await controller.send();

      expect(sender.lastRequest?.token, 'device-token');
      expect(sender.lastRequest?.draft, controller.draft);
    });

    test('records the response and clears any earlier error', () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);

      await controller.send();

      expect(controller.lastResponse?.payloadId, 'sandbox-1');
      expect(controller.lastError, isNull);
      expect(controller.isSending, isFalse);
    });

    test(
      'records a failure instead of throwing, and drops the stale response',
      () async {
        final sender = FakeNotificationSender();
        final controller = _controller(sender);
        await controller.send();

        sender.failWith = StateError('functions unreachable');
        await controller.send();

        expect(controller.lastError, contains('functions unreachable'));
        expect(controller.lastResponse, isNull);
        expect(controller.isSending, isFalse);
      },
    );

    test('notifies listeners while sending and again when finished', () async {
      final controller = _controller(FakeNotificationSender());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.send();

      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('does not send when the draft is invalid, even if asked', () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);
      controller.editDraft(controller.draft.copyWith(title: '', body: ''));

      await controller.send();

      expect(sender.lastRequest, isNull);
    });
  });
}
