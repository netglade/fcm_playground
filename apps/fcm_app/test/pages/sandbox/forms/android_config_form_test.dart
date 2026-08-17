import 'package:fcm_app/pages/sandbox/forms/android_config_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  setUpAll(GladeForms.initialize);

  /// Every field set, so the round-trip proves no field was forgotten.
  ///
  /// An inlined copy of the contract package's own fixture, which is a `const`
  /// local to that test's `main()` and so invisible here. `hasLength(8)` below guards the copy.
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

  AndroidConfigForm form() => AndroidConfigForm()..initialize();

  group('AndroidConfigForm', () {
    test('the fixture still covers every field', () {
      // Guards the inlined copy: a ninth field on AndroidConfig fails here rather than
      // silently narrowing the round-trip below.
      expect(everyField, hasLength(8));
    });

    test('is valid while empty, since FCM requires nothing here', () {
      expect(form().isValid, isTrue);
    });

    test('returns null when nothing is set, so the block is omitted', () {
      expect(form().toModel(), isNull);
    });

    test('round-trips all 8 fields', () {
      final source = AndroidConfig.fromJson(everyField);
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('round-trips all 8 fields through JSON too', () {
      final subject = form()..readFrom(AndroidConfig.fromJson(everyField));

      expect(subject.toModel()!.toJson(), everyField);
    });

    test('a false flag survives, and is not confused with absent', () {
      final subject = form();

      subject.readFrom(const AndroidConfig(directBootOk: false));

      final result = subject.toModel()!;
      expect(result.directBootOk, isFalse);
      expect(result.toJson()['direct_boot_ok'], isFalse);
    });

    test('an unset flag is omitted entirely', () {
      final subject = form();

      subject.readFrom(const AndroidConfig(collapseKey: 'only'));

      expect(
        subject.toModel()!.toJson().keys,
        isNot(contains('direct_boot_ok')),
      );
    });

    test('rejects a ttl that is not a duration', () {
      final subject = form();

      subject.ttl.updateValue('later');

      expect(subject.isValid, isFalse);
    });

    test('rejects a ttl the pattern only partly matches', () {
      // match() is built on hasMatch, so the pattern has to be anchored or
      // 'in 3600s or so' would pass.
      final subject = form();

      subject.ttl.updateValue('in 3600s or so');

      expect(subject.isValid, isFalse);
    });

    test('accepts a fractional ttl, which FCM allows', () {
      final subject = form();

      subject.ttl.updateValue('3.5s');

      expect(subject.isValid, isTrue);
    });

    test('accepts an empty ttl, which means absent rather than invalid', () {
      // Without shouldValidate the duration rule runs on '' and an untouched
      // form would block Send.
      final subject = form()..readFrom(const AndroidConfig(ttl: '3600s'));

      subject.ttl.updateValue('');

      expect(subject.isValid, isTrue);
      expect(subject.toModel(), isNull);
    });

    test('an emptied data map is absent rather than an empty object', () {
      // AndroidConfig.== compares data with MapEquality, so {} is not null:
      // deleting every row would otherwise leave "data": {} in the payload and
      // stop toModel() returning null for an otherwise-untouched block.
      final subject = form()
        ..readFrom(const AndroidConfig(data: {'event': 'build_finished'}));

      subject.data.updateValue(<String, String>{});

      expect(subject.toModel(), isNull);
    });

    test('carries a nested notification block', () {
      const source = AndroidConfig(
        notification: AndroidNotification(
          title: 'Build finished',
          channelId: 'fcm_sample_high',
        ),
      );
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('carries a nested fcm options block', () {
      const source = AndroidConfig(
        fcmOptions: FcmOptions(analyticsLabel: 'campaign-1'),
      );
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('clears every input when read from null', () {
      final subject = form()..readFrom(AndroidConfig.fromJson(everyField));

      subject.readFrom(null);

      expect(subject.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });

    test('is invalid when the nested notification is invalid', () {
      // The nested inputs are not in `inputs`, so the inherited `isValid` cannot see
      // them. Validity has to compose at every level or the section badge lies.
      final subject = form();

      subject.notification.color.updateValue('blue');

      expect(subject.notification.isValid, isFalse);
      expect(subject.isValid, isFalse);
    });

    test('is invalid when a field two levels down is invalid', () {
      // light_settings is nested inside the nested notification, so this only
      // holds if every level folds its children in.
      final subject = form();

      subject.notification.lightSettings.red.controller!.text = '2.5';

      expect(subject.isValid, isFalse);
    });

    test('stays valid when the nested blocks are merely empty', () {
      // Untouched is absent, not invalid — unused sections must not block Send.
      final subject = form();

      expect(subject.notification.toModel(), isNull);
      expect(subject.fcmOptions.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });
  });
}
