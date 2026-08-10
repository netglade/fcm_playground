import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _validator = NotificationDraftValidator();

const _valid = NotificationDraft(
  event: NotificationEvent.promo,
  title: 'Sale',
  body: 'Half price.',
);

List<String> _fields(NotificationDraft draft) =>
    _validator.validate(draft).map((problem) => problem.field).toList();

void main() {
  group('NotificationDraftValidator', () {
    test('a well-formed draft has no problems', () {
      expect(_validator.validate(_valid), isEmpty);
    });

    test('every gallery scenario validates clean', () {
      for (final scenario in notificationGallery) {
        expect(
          _validator.validate(scenario.draft),
          isEmpty,
          reason: scenario.id,
        );
      }
    });

    test('a visible notification needs a title and a body', () {
      final blank = _valid.copyWith(title: '  ', body: '');

      expect(_fields(blank), containsAll(['title', 'body']));
    });

    test('a silent message may have neither, since nothing is shown', () {
      final silent = _valid.copyWith(
        title: '',
        body: '',
        delivery: const NotificationDelivery(asNotification: false),
      );

      expect(_validator.validate(silent), isEmpty);
    });

    test('a blank extra data key is a problem', () {
      final draft = _valid.copyWith(data: const {'  ': 'value'});

      expect(_fields(draft), contains('data'));
    });

    test('an extra data key may not collide with a reserved payload key', () {
      for (final reserved in PushMessageParser.reservedKeys) {
        final draft = _valid.copyWith(data: {reserved: 'value'});

        expect(_fields(draft), contains('data'), reason: reserved);
      }
    });

    test('the event key is reserved too, since the builder writes it', () {
      final draft = _valid.copyWith(data: const {'event': 'promo'});

      expect(_fields(draft), contains('data'));
    });

    test(
      'the reserved set is core\'s keys plus event, defined in one place',
      () {
        expect(NotificationDraftValidator.reservedDataKeys, {
          ...PushMessageParser.reservedKeys,
          'event',
        });
      },
    );

    test('a problem names its field and reason when printed', () {
      const problem = DraftProblem('title', 'must not be blank');

      expect('$problem', 'title: must not be blank');
    });
  });
}
