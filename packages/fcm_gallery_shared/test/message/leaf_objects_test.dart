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

  group('FcmNotification', () {
    test('round-trips every field', () {
      const json = {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
        'image': 'https://example.test/build.png',
      };

      expect(FcmNotification.fromJson(json).toJson(), json);
    });

    test('omits absent fields rather than writing null', () {
      const notification = FcmNotification(title: 'Only a title');

      expect(notification.toJson(), {'title': 'Only a title'});
    });

    test('rejects a field FCM does not define', () {
      expect(
        () => FcmNotification.fromJson({'titel': 'typo'}),
        throwsFormatMentioning('unknown field "titel"'),
      );
    });

    test('compares by value', () {
      expect(
        const FcmNotification(title: 'a', body: 'b'),
        const FcmNotification(title: 'a', body: 'b'),
      );
    });
  });

  group('the three fcm_options types', () {
    test('the generic one carries only an analytics label', () {
      const json = {'analytics_label': 'campaign-1'};

      expect(FcmOptions.fromJson(json).toJson(), json);
    });

    test('the APNs one adds an image', () {
      const json = {
        'image': 'https://example.test/a.png',
        'analytics_label': 'x',
      };

      expect(ApnsFcmOptions.fromJson(json).toJson(), json);
    });

    test('the WebPush one adds a link', () {
      const json = {
        'link': 'https://example.test/open',
        'analytics_label': 'x',
      };

      expect(WebpushFcmOptions.fromJson(json).toJson(), json);
    });

    test('the generic one rejects a link, which only WebPush accepts', () {
      expect(
        () => FcmOptions.fromJson({'link': 'https://example.test'}),
        throwsFormatMentioning('unknown field "link"'),
      );
    });
  });

  group('LightSettings', () {
    const json = {
      'color': {'red': 1.0, 'green': 0.5, 'blue': 0.0, 'alpha': 1.0},
      'light_on_duration': '1s',
      'light_off_duration': '0.5s',
    };

    test('round-trips, keeping the durations as written', () {
      expect(LightSettings.fromJson(json).toJson(), json);
    });

    test('reads an integer colour component as a number', () {
      final settings = LightSettings.fromJson({
        ...json,
        'color': {'red': 1, 'green': 0, 'blue': 0, 'alpha': 1},
      });

      expect(settings.color.red, 1.0);
    });

    test(
      'rejects a colour missing a component, since FCM requires all four',
      () {
        expect(
          () => LightSettings.fromJson({
            ...json,
            'color': {'red': 1.0, 'green': 0.5, 'blue': 0.0},
          }),
          throwsFormatMentioning('alpha'),
        );
      },
    );

    test(
      'rejects light settings with no duration, since FCM requires both',
      () {
        expect(
          () => LightSettings.fromJson({'color': json['color']}),
          throwsFormatMentioning('light_on_duration'),
        );
      },
    );

    test('names the nested path when the colour is malformed', () {
      expect(
        () => LightSettings.fromJson({
          ...json,
          'color': {'red': 'red'},
        }),
        throwsFormatMentioning('color.red'),
      );
    });
  });
}
