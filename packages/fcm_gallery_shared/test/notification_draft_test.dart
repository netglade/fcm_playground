import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _draft = NotificationDraft(
  event: NotificationEvent.chatMessage,
  title: 'Ada replied',
  body: 'See you at the seminar.',
  data: {'deepLink': '/chats/7'},
  delivery: NotificationDelivery(priority: NotificationPriority.normal),
);

void main() {
  group('NotificationDraft', () {
    test('round-trips through JSON, extra data included', () {
      expect(NotificationDraft.fromJson(_draft.toJson()), _draft);
    });

    test(
      'defaults to no extra data and a visible high-priority notification',
      () {
        const draft = NotificationDraft(
          event: NotificationEvent.promo,
          title: 'Sale',
          body: 'Half price.',
        );

        expect(draft.data, isEmpty);
        expect(draft.delivery, const NotificationDelivery());
      },
    );

    test('copyWith replaces only what it is given', () {
      final edited = _draft.copyWith(title: 'Ada replied twice');

      expect(edited.title, 'Ada replied twice');
      expect(edited.body, _draft.body);
      expect(edited.data, _draft.data);
      expect(edited.delivery, _draft.delivery);
    });

    test('an unknown event is a format error', () {
      final json = _draft.toJson()..['event'] = 'nope';

      expect(() => NotificationDraft.fromJson(json), throwsFormatException);
    });

    test('a missing event is a format error', () {
      final json = _draft.toJson()..remove('event');

      expect(() => NotificationDraft.fromJson(json), throwsFormatException);
    });

    test('non-string data values are stringified rather than rejected', () {
      final draft = NotificationDraft.fromJson({
        ..._draft.toJson(),
        'data': {'attempt': 2},
      });

      expect(draft.data, {'attempt': '2'});
    });

    test(
      'data is unmodifiable, so a draft cannot be mutated after the fact',
      () {
        final draft = NotificationDraft.fromJson(_draft.toJson());

        expect(() => draft.data['sneaky'] = 'yes', throwsUnsupportedError);
      },
    );
  });
}
