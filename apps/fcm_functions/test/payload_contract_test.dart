import 'package:core/core.dart';
import 'package:fcm_functions/notification_message_builder.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _builder = NotificationMessageBuilder();
const _validator = NotificationDraftValidator();

final _sentAt = DateTime.utc(2026, 8, 10, 9, 30);

/// Builds the message for [draft] and parses its data payload the same way a
/// receiving device would, so a mismatch between what the builder writes and
/// what `core` accepts shows up here rather than on a device.
PushMessage _roundTrip(NotificationDraft draft) {
  final message = _builder.build(
    draft: draft,
    token: 'device-token',
    payloadId: 'sandbox-1',
    sentAt: _sentAt,
  );

  return const PushMessageParser().parse(message.data ?? {});
}

void main() {
  // The builder lives in fcm_functions and the parser lives in core, and
  // nothing else in this branch imports both. A validator rule that
  // disagreed with the parser's requirements once shipped a payload the
  // device silently dropped — see notification_draft_validator.dart.
  group('the built payload is one core can parse', () {
    for (final scenario in notificationGallery) {
      test('${scenario.id} round-trips', () {
        final message = _roundTrip(scenario.draft);

        expect(message.id, 'sandbox-1');
        expect(message.title, scenario.draft.title);
        expect(message.body, scenario.draft.body);
        expect(message.sentAt, _sentAt);
        expect(message.data['event'], scenario.draft.event.wireName);
      });
    }

    test('a silent draft round-trips too', () {
      final silent = notificationGallery.first.draft.copyWith(
        delivery: const NotificationDelivery(asNotification: false),
      );

      expect(_roundTrip(silent).title, isNotEmpty);
    });

    test('anything the validator accepts, the parser accepts', () {
      for (final scenario in notificationGallery) {
        expect(
          _validator.validate(scenario.draft),
          isEmpty,
          reason: scenario.id,
        );
        expect(
          () => _roundTrip(scenario.draft),
          returnsNormally,
          reason: scenario.id,
        );
      }
    });
  });
}
