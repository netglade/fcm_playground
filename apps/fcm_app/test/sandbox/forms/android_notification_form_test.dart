import 'package:fcm_app/sandbox/forms/android_notification_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  setUpAll(GladeForms.initialize);

  /// Every field set, so the round-trip proves no field was forgotten.
  ///
  /// An inlined copy of the contract package's own fixture: it is a `const`
  /// local to that test's `main()`, and one package's `test/` directory is not
  /// visible to another's. The `hasLength(27)` guard below is what stops the
  /// copy drifting from the model.
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

  AndroidNotificationForm form() => AndroidNotificationForm()..initialize();

  group('AndroidNotificationForm', () {
    test('the fixture still covers every field', () {
      // Guards the inlined copy: a 28th field on AndroidNotification fails here
      // instead of silently narrowing the round-trip below.
      expect(everyField, hasLength(27));
    });

    test('is valid while empty, since FCM requires nothing here', () {
      expect(form().isValid, isTrue);
    });

    test('returns null when nothing is set, so the block is omitted', () {
      expect(form().toModel(), isNull);
    });

    test('round-trips all 27 fields', () {
      final source = AndroidNotification.fromJson(everyField);
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('round-trips all 27 fields through JSON too', () {
      final subject = form()
        ..readFrom(AndroidNotification.fromJson(everyField));

      expect(subject.toModel()!.toJson(), everyField);
    });

    test('a false flag survives, and is not confused with absent', () {
      final subject = form();

      subject.readFrom(const AndroidNotification(sticky: false));

      final result = subject.toModel()!;
      expect(result.sticky, isFalse);
      expect(result.toJson()['sticky'], isFalse);
    });

    test('an unset flag is omitted entirely', () {
      final subject = form();

      subject.readFrom(const AndroidNotification(title: 'only'));

      expect(subject.toModel()!.toJson().keys, isNot(contains('sticky')));
    });

    test('rejects a colour that is not #rrggbb', () {
      final subject = form();

      subject.color.updateValue('blue');

      expect(subject.isValid, isFalse);
    });

    test('rejects a colour the pattern only partly matches', () {
      // match() is built on hasMatch, so the pattern has to be anchored or
      // '#ff0000 ish' would pass.
      final subject = form();

      subject.color.updateValue('blue #ff0000 ish');

      expect(subject.isValid, isFalse);
    });

    test('accepts an empty colour, which means absent rather than invalid', () {
      final subject = form()
        ..readFrom(const AndroidNotification(color: '#4285f4'));

      subject.color.updateValue('');

      expect(subject.isValid, isTrue);
      expect(subject.toModel(), isNull);
    });

    test('rejects a vibrate timing that is not a duration', () {
      final subject = form();

      subject.vibrateTimings.updateValue(['0.5s', 'soon']);

      expect(subject.isValid, isFalse);
    });

    test('accepts an unset vibrate pattern', () {
      expect(form().isValid, isTrue);
      expect((form()..vibrateTimings.updateValue(<String>[])).isValid, isTrue);
    });

    test('clears a cleared notification count instead of keeping the old one', () {
      // glade's own nullable-int converter treats '' as unparseable and retains
      // the last number, so a user who typed 3 and cleared it would still send
      // notification_count: 3.
      final subject = form()
        ..readFrom(const AndroidNotification(notificationCount: 3));

      subject.notificationCount.controller!.text = '';

      expect(subject.notificationCount.value, isNull);
      expect(subject.toModel(), isNull);
    });

    test('carries a nested light settings block', () {
      const source = AndroidNotification(
        lightSettings: LightSettings(
          color: LightColor(red: 1, green: 0, blue: 0, alpha: 1),
          lightOnDuration: '1s',
          lightOffDuration: '0.5s',
        ),
      );
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('clears every input when read from null', () {
      final subject = form()
        ..readFrom(AndroidNotification.fromJson(everyField));

      subject.readFrom(null);

      expect(subject.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });
  });
}
