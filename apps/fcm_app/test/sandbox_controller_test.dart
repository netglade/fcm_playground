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
    test('opens on the first preset, so the page is sendable immediately', () {
      final controller = controllerWith();

      expect(controller.title, notificationGallery.first.draft.title);
      expect(controller.problems, isEmpty);
      expect(controller.canSend, isTrue);
    });

    test('replaces the form when a scenario is applied', () {
      final controller = controllerWith();
      final promo = notificationGallery.firstWhere(
        (scenario) => scenario.id == 'promo',
      );

      controller.applyScenario(promo);

      expect(controller.title, promo.draft.title);
      // MapEntry has no value equality in Dart, so compare the entries as
      // records rather than the MapEntry objects themselves.
      expect(
        controller.entries.map((entry) => (entry.key, entry.value)),
        promo.draft.data.entries.map((entry) => (entry.key, entry.value)),
      );
    });

    test('bumps the revision on a scenario, so the fields are rebuilt', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.applyScenario(notificationGallery.last);

      expect(controller.scenarioRevision, greaterThan(before));
    });

    test('does not bump the revision on an ordinary edit', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.edit(title: 'Typed by hand');

      expect(controller.scenarioRevision, before);
    });

    test('reports a blank title and blocks Send', () {
      final controller = controllerWith();

      controller.edit(title: '  ');

      expect(controller.problems, contains(isA<DraftProblem>()));
      expect(controller.problems.first.field, 'title');
      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, isNotNull);
    });

    test('reports a duplicated data key, which the draft alone could not', () {
      final controller = controllerWith();

      controller.edit(
        entries: const [MapEntry('event', 'a'), MapEntry('event', 'b')],
      );

      expect(controller.problems, [
        const DraftProblem('data.event', 'is duplicated'),
      ]);
    });

    test('reports a data key that collides with a reserved payload key', () {
      final controller = controllerWith();

      controller.edit(entries: const [MapEntry('sentAt', 'now')]);

      expect(controller.problems.single.field, 'data.sentAt');
    });

    test('blocks Send with a reason when there is no token yet', () {
      final controller = controllerWith(token: null);

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('token'));
    });

    test('does not call the sender when there is no token', () async {
      final controller = controllerWith(token: null);

      await controller.send();

      expect(sender.sent, isEmpty);
      expect(controller.state, isA<SandboxFailed>());
    });

    test('sends the current draft with the device token', () async {
      final controller = controllerWith();

      controller.edit(
        title: 'Hand written',
        body: 'From the sandbox',
        entries: const [MapEntry('event', 'manual')],
      );
      await controller.send();

      expect(sender.sent, hasLength(1));
      expect(sender.sent.single.token, 'device-token');
      expect(
        sender.sent.single.draft,
        const NotificationDraft(
          title: 'Hand written',
          body: 'From the sandbox',
          data: {'event': 'manual'},
        ),
      );
    });

    test('lands on Sent with the response, so the id can be shown', () async {
      final controller = controllerWith();

      await controller.send();

      expect(controller.state, isA<SandboxSent>());
      expect(
        (controller.state as SandboxSent).response.payloadId,
        'api-1754812345678901',
      );
    });

    test(
      'refuses to send an invalid draft, without calling the sender',
      () async {
        final controller = controllerWith();

        controller.edit(body: '');
        await controller.send();

        expect(sender.sent, isEmpty);
        expect(controller.state, isA<SandboxIdle>());
      },
    );

    test('lands on Failed and keeps the form when the send fails', () async {
      final controller = controllerWith(
        withSender: FakeNotificationSender(
          failure: const NotificationSendException('The API is unreachable'),
        ),
      );

      controller.edit(title: 'Kept');
      await controller.send();

      expect(controller.state, isA<SandboxFailed>());
      expect(
        (controller.state as SandboxFailed).message,
        'The API is unreachable',
      );
      expect(controller.title, 'Kept');
    });

    test('notifies listeners as it goes', () async {
      final controller = controllerWith();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.edit(title: 'Typed');
      await controller.send();

      expect(notifications, greaterThanOrEqualTo(3));
    });
  });
}
