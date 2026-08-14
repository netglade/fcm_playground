import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  Matcher throwsFormatMentioning(String fragment) => throwsA(
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      contains(fragment),
    ),
  );

  const everyBlock = {
    'data': {'event': 'build_finished'},
    'notification': {'title': 'Build finished', 'body': 'Ready.'},
    'android': {'priority': 'HIGH'},
    'webpush': {
      'headers': {'TTL': '60'},
    },
    'apns': {
      'headers': {'apns-priority': '10'},
    },
    'fcm_options': {'analytics_label': 'campaign-1'},
  };

  test('round-trips every block', () {
    expect(FcmMessage.fromJson(everyBlock).toJson(), everyBlock);
  });

  test('the round-trip really covered every block', () {
    expect(everyBlock, hasLength(6));
  });

  test('accepts a notification-only message', () {
    const json = {
      'notification': {'title': 'Hi'},
    };

    expect(FcmMessage.fromJson(json).toJson(), json);
  });

  test('accepts a data-only message, which is the silent path', () {
    const json = {
      'data': {'event': 'sync'},
    };

    final message = FcmMessage.fromJson(json);

    expect(message.notification, isNull);
    expect(message.toJson(), json);
  });

  test('accepts an empty message, leaving FCM to reject it', () {
    expect(FcmMessage.fromJson(const {}).toJson(), isEmpty);
  });

  group('the delivery target', () {
    test('rejects a token, explaining that the server sets it', () {
      expect(
        () => FcmMessage.fromJson({'token': 'e…'}),
        throwsFormatMentioning(
          'message.token: the server sets the delivery target',
        ),
      );
    });

    test('rejects a topic', () {
      expect(
        () => FcmMessage.fromJson({'topic': 'builds'}),
        throwsFormatMentioning('message.topic'),
      );
    });

    test('rejects a condition', () {
      expect(
        () => FcmMessage.fromJson({'condition': "'builds' in topics"}),
        throwsFormatMentioning('message.condition'),
      );
    });

    test('never writes a target, so one cannot leak back out', () {
      final json = FcmMessage.fromJson(everyBlock).toJson();

      expect(json.keys, isNot(contains('token')));
      expect(json.keys, isNot(contains('topic')));
      expect(json.keys, isNot(contains('condition')));
    });
  });

  test('rejects the output-only name field', () {
    expect(
      () => FcmMessage.fromJson({'name': 'projects/p/messages/1'}),
      throwsFormatMentioning('unknown field "name"'),
    );
  });

  test('names the deepest path when a nested block is malformed', () {
    expect(
      () => FcmMessage.fromJson({
        'android': {
          'notification': {
            'light_settings': {
              'color': {'red': 'red'},
            },
          },
        },
      }),
      throwsFormatMentioning('android.notification.light_settings.color.red'),
    );
  });
}
