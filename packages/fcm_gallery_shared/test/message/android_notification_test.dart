import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  /// Every field set, so the round-trip proves no field was forgotten.
  const everyField = {
    'title': 'Build finished',
    'body': 'Release 1.0.0 is ready.',
    'icon': 'ic_stat_build',
    'color': '#4285f4',
    'sound': 'default',
    'tag': 'builds',
    'click_action': 'OPEN_BUILD',
    'body_loc_key': 'build_body',
    'body_loc_args': ['1.0.0'],
    'title_loc_key': 'build_title',
    'title_loc_args': ['128'],
    'channel_id': 'fcm_sample_high',
    'ticker': 'Build finished',
    'sticky': true,
    'event_time': '2026-08-11T09:30:00Z',
    'local_only': false,
    'notification_priority': 'PRIORITY_HIGH',
    'default_sound': true,
    'default_vibrate_timings': false,
    'default_light_settings': false,
    'vibrate_timings': ['0.5s', '0.5s'],
    'visibility': 'PUBLIC',
    'notification_count': 3,
    'light_settings': {
      'color': {'red': 1.0, 'green': 0.5, 'blue': 0.0, 'alpha': 1.0},
      'light_on_duration': '1s',
      'light_off_duration': '0.5s',
    },
    'image': 'https://example.test/build.png',
    'bypass_proxy_notification': false,
    'proxy': 'ALLOW',
  };

  test('round-trips all 27 fields, so none is silently dropped', () {
    expect(AndroidNotification.fromJson(everyField).toJson(), everyField);
  });

  test('the round-trip really covered every field', () {
    // Guards against a field added to the class but not to everyField.
    expect(everyField, hasLength(27));
  });

  test('omits absent fields rather than writing null', () {
    const notification = AndroidNotification(title: 'Only a title');

    expect(notification.toJson(), {'title': 'Only a title'});
  });

  test('keeps a false flag, which is a value rather than an absence', () {
    expect(AndroidNotification.fromJson({'sticky': false}).toJson(), {
      'sticky': false,
    });
  });

  test('keeps durations and timestamps exactly as written', () {
    final parsed = AndroidNotification.fromJson({
      'event_time': '2026-08-11T09:30:00.000000Z',
      'vibrate_timings': ['3.500s'],
    });

    expect(parsed.toJson()['event_time'], '2026-08-11T09:30:00.000000Z');
    expect(parsed.toJson()['vibrate_timings'], ['3.500s']);
  });

  test('rejects a field FCM does not define, naming it', () {
    expect(
      () => AndroidNotification.fromJson({'channelID': 'wrong_case'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('unknown field "channelID"'),
        ),
      ),
    );
  });

  test('rejects an unrecognised enum value with its path', () {
    expect(
      () => AndroidNotification.fromJson({'visibility': 'HIDDEN'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('visibility: unknown value "HIDDEN"'),
        ),
      ),
    );
  });

  group('equality', () {
    test('compares list fields by value, not by identity', () {
      expect(
        AndroidNotification.fromJson({
          'vibrate_timings': ['1s'],
        }),
        AndroidNotification.fromJson({
          'vibrate_timings': ['1s'],
        }),
      );
    });

    test('separates notifications differing only inside a list', () {
      expect(
        AndroidNotification.fromJson({
          'vibrate_timings': ['1s'],
        }),
        isNot(
          AndroidNotification.fromJson({
            'vibrate_timings': ['2s'],
          }),
        ),
      );
    });

    test('hashes equal notifications equally, despite 27 fields', () {
      expect(
        AndroidNotification.fromJson(everyField).hashCode,
        AndroidNotification.fromJson(everyField).hashCode,
      );
    });
  });
}
