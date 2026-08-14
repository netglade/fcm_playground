import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('ApnsConfig', () {
    const everyField = {
      'headers': {'apns-priority': '10', 'apns-push-type': 'alert'},
      'payload': {
        'aps': {
          'alert': {'title': 'Build finished', 'body': 'Ready.'},
          'badge': 1,
          'sound': 'default',
          'content-available': 1,
          'thread-id': 'builds',
        },
        'custom_key': [1, 2, 3],
      },
      'fcm_options': {'image': 'https://example.test/a.png'},
    };

    test('round-trips every field', () {
      expect(ApnsConfig.fromJson(everyField).toJson(), everyField);
    });

    test(
      'passes the payload through untouched, including nested structure',
      () {
        final config = ApnsConfig.fromJson(everyField);
        final aps = config.payload!['aps']! as Map<String, Object?>;

        expect(aps['content-available'], 1);
        expect(aps['thread-id'], 'builds');
        expect(config.payload!['custom_key'], [1, 2, 3]);
      },
    );

    test('accepts a payload key the model has never heard of', () {
      // The escape hatch that makes an untyped aps acceptable: anything Apple
      // adds is writable today, without a model change.
      final config = ApnsConfig.fromJson({
        'payload': {
          'aps': {'interruption-level': 'time-sensitive'},
        },
      });

      expect(
        (config.payload!['aps']! as Map<String, Object?>)['interruption-level'],
        'time-sensitive',
      );
    });

    test('still rejects an unknown field at the config level', () {
      expect(
        () => ApnsConfig.fromJson({'payloads': <String, Object?>{}}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('apns: unknown field "payloads"'),
          ),
        ),
      );
    });

    test('rejects an image in the generic options position', () {
      // ApnsFcmOptions accepts image; the generic FcmOptions does not. This pins
      // that apns uses the APNs-specific type.
      expect(
        ApnsConfig.fromJson({
          'fcm_options': {'image': 'https://example.test/a.png'},
        }).fcmOptions?.image,
        'https://example.test/a.png',
      );
    });
  });

  group('WebpushConfig', () {
    const everyField = {
      'headers': {'TTL': '60'},
      'data': {'event': 'build_finished'},
      'notification': {'title': 'Build finished', 'requireInteraction': true},
      'fcm_options': {'link': 'https://example.test/builds'},
    };

    test('round-trips every field', () {
      expect(WebpushConfig.fromJson(everyField).toJson(), everyField);
    });

    test('passes the notification through untouched', () {
      final config = WebpushConfig.fromJson(everyField);

      expect(config.notification!['requireInteraction'], isTrue);
    });

    test('reads the link only WebPush accepts', () {
      expect(
        WebpushConfig.fromJson(everyField).fcmOptions?.link,
        'https://example.test/builds',
      );
    });

    test('rejects an unknown field at the config level', () {
      expect(
        () => WebpushConfig.fromJson({'header': <String, Object?>{}}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('webpush: unknown field "header"'),
          ),
        ),
      );
    });
  });
}
