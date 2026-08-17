import 'package:fcm_app/sandbox/forms/light_settings_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  setUpAll(GladeForms.initialize);

  const complete = LightSettings(
    color: LightColor(red: 1, green: 0.5, blue: 0, alpha: 1),
    lightOnDuration: '1s',
    lightOffDuration: '0.5s',
  );

  LightSettingsForm form() => LightSettingsForm()..initialize();

  group('LightSettingsForm', () {
    test('returns null while empty, so the block is omitted', () {
      expect(form().toModel(), isNull);
    });

    test('is valid while empty — an omitted block is not an invalid one', () {
      // The fields are required *if the block is present*. An untouched form
      // must not block Send, or an unused light_settings section would make the
      // whole payload unsendable.
      expect(form().isValid, isTrue);
    });

    test('round-trips a complete block, keeping the durations as written', () {
      final subject = form()..readFrom(complete);

      expect(subject.toModel(), complete);
      expect(subject.toModel()!.lightOffDuration, '0.5s');
    });

    test('returns null when a colour component is missing', () {
      // FCM requires all four. Returning a partial colour would earn an opaque
      // 400 from Google instead of a local error the user can act on.
      final subject = form()..readFrom(complete);

      subject.alpha.controller!.text = '';

      expect(subject.toModel(), isNull);
    });

    test('returns null when a duration is missing', () {
      final subject = form()..readFrom(complete);

      subject.lightOnDuration.updateValue('');

      expect(subject.toModel(), isNull);
    });

    test('rejects a colour component above 1.0', () {
      final subject = form()..readFrom(complete);

      subject.red.controller!.text = '2.5';

      expect(subject.isValid, isFalse);
    });

    test('rejects a colour component below 0.0', () {
      final subject = form()..readFrom(complete);

      subject.green.controller!.text = '-1';

      expect(subject.isValid, isFalse);
    });

    test('clears every input when read from null', () {
      final subject = form()..readFrom(complete);

      subject.readFrom(null);

      expect(subject.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });
  });
}
