import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  const everyField = {
    'collapse_key': 'builds',
    'priority': 'HIGH',
    'ttl': '3600s',
    'restricted_package_name': 'cz.netglade.fcm_app',
    'data': {'event': 'build_finished'},
    'notification': {
      'title': 'Build finished',
      'channel_id': 'fcm_sample_high',
    },
    'fcm_options': {'analytics_label': 'campaign-1'},
    'direct_boot_ok': true,
  };

  test('round-trips every field', () {
    expect(AndroidConfig.fromJson(everyField).toJson(), everyField);
  });

  test('the round-trip really covered every field', () {
    expect(everyField, hasLength(8));
  });

  test('keeps arbitrary data keys, which are the caller\'s own', () {
    final config = AndroidConfig.fromJson({
      'data': {'anything_at_all': '1', 'even_this': '2'},
    });

    expect(config.data, {'anything_at_all': '1', 'even_this': '2'});
  });

  test('rejects an unknown field at the config level', () {
    expect(
      () => AndroidConfig.fromJson({'collapseKey': 'wrong_case'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('unknown field "collapseKey"'),
        ),
      ),
    );
  });

  test('names the nested path when the notification is malformed', () {
    expect(
      () => AndroidConfig.fromJson({
        'notification': {'titel': 'typo'},
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('android.notification: unknown field "titel"'),
        ),
      ),
    );
  });

  test('compares data maps by value', () {
    expect(
      AndroidConfig.fromJson({
        'data': {'k': 'v'},
      }),
      AndroidConfig.fromJson({
        'data': {'k': 'v'},
      }),
    );
  });
}
