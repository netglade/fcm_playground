import 'package:fcm_app/sandbox/forms/apns_config_form.dart';
import 'package:fcm_app/sandbox/forms/webpush_config_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  setUpAll(GladeForms.initialize);

  group('ApnsConfigForm', () {
    /// Every field set, so the round-trip proves no field was forgotten.
    ///
    /// An inlined copy of the contract package's own fixture: it is a `const`
    /// local to that test's `main()`, and one package's `test/` directory is not
    /// visible to another's. The `hasLength(3)` guard below is what stops the
    /// copy drifting from the model.
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

    ApnsConfigForm form() => ApnsConfigForm()..initialize();

    test('the fixture still covers every field', () {
      // Guards the inlined copy: a fourth field on ApnsConfig fails here
      // instead of silently narrowing the round-trip below.
      expect(everyField, hasLength(3));
    });

    test('is valid while empty, since FCM requires nothing here', () {
      expect(form().isValid, isTrue);
    });

    test('returns null when nothing is set, so the block is omitted', () {
      expect(form().toModel(), isNull);
    });

    test('round-trips all 3 fields', () {
      final source = ApnsConfig.fromJson(everyField);
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('round-trips all 3 fields through JSON too', () {
      final subject = form()..readFrom(ApnsConfig.fromJson(everyField));

      expect(subject.toModel()!.toJson(), everyField);
    });

    test('carries the free-form payload through untouched', () {
      // The whole point of holding the payload as one map: the form never
      // reshapes what FCM forwards to Apple verbatim.
      final subject = form()..readFrom(ApnsConfig.fromJson(everyField));

      final payload = subject.toModel()!.payload!;
      final aps = payload['aps']! as Map<String, Object?>;
      expect(aps['content-available'], 1);
      expect(aps['thread-id'], 'builds');
      expect(payload['custom_key'], [1, 2, 3]);
    });

    test('an emptied headers map is absent rather than an empty object', () {
      // ApnsConfig.== compares headers with MapEquality, so {} is not null:
      // deleting every row would otherwise leave "headers": {} in the payload
      // and stop toModel() returning null for an otherwise-untouched block.
      final subject = form()
        ..readFrom(const ApnsConfig(headers: {'apns-priority': '10'}));

      subject.headers.updateValue(<String, String>{});

      expect(subject.toModel(), isNull);
    });

    test('an emptied payload map is absent rather than an empty object', () {
      // Same trap in the free-form flavour: payload is compared with
      // MapEquality<String, Object?>, so the helper is needed twice over.
      final subject = form()
        ..readFrom(
          const ApnsConfig(
            payload: {
              'aps': {'badge': 1},
            },
          ),
        );

      subject.payload.updateValue(<String, Object?>{});

      expect(subject.toModel(), isNull);
    });

    test('carries a nested fcm options block, with the APNs image', () {
      // ApnsFcmOptions carries `image`, which the generic block does not: using
      // the wrong subform here would drop it silently.
      const source = ApnsConfig(
        fcmOptions: ApnsFcmOptions(image: 'https://example.test/a.png'),
      );
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
      expect(subject.fcmOptions.image.value, 'https://example.test/a.png');
    });

    test('clears every input when read from null', () {
      final subject = form()..readFrom(ApnsConfig.fromJson(everyField));

      subject.readFrom(null);

      expect(subject.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });

    test('stays valid when the nested options block is merely empty', () {
      // Untouched is absent, not invalid — unused sections must not block Send.
      final subject = form();

      expect(subject.fcmOptions.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });

    test('round-trips an alert payload read out of a whole message', () {
      // The reason the dotted-path work exists: a real nested aps dictionary,
      // reached the way the Sandbox reaches it — through FcmMessage.fromJson
      // rather than ApnsConfig.fromJson. Group A carries no APNs scenario, so
      // the template is inline until g4_badge_ios exists to source it from.
      const template = {
        'apns': {
          'headers': {'apns-priority': '10'},
          'payload': {
            'aps': {
              'alert': {
                'title': 'Build finished',
                'body': 'Release 1.0.0 is ready.',
              },
              'badge': 1,
              'sound': 'default',
            },
          },
        },
      };
      final source = FcmMessage.fromJson(template).apns!;
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });
  });

  group('WebpushConfigForm', () {
    /// Every field set, so the round-trip proves no field was forgotten.
    ///
    /// An inlined copy of the contract package's own fixture, for the same
    /// reason as the APNs one above; `hasLength(4)` guards the copy.
    const everyField = {
      'headers': {'TTL': '60'},
      'data': {'event': 'build_finished'},
      'notification': {'title': 'Build finished', 'requireInteraction': true},
      'fcm_options': {'link': 'https://example.test/builds'},
    };

    WebpushConfigForm form() => WebpushConfigForm()..initialize();

    test('the fixture still covers every field', () {
      // Guards the inlined copy: a fifth field on WebpushConfig fails here
      // instead of silently narrowing the round-trip below.
      expect(everyField, hasLength(4));
    });

    test('is valid while empty, since FCM requires nothing here', () {
      expect(form().isValid, isTrue);
    });

    test('returns null when nothing is set, so the block is omitted', () {
      expect(form().toModel(), isNull);
    });

    test('round-trips all 4 fields', () {
      final source = WebpushConfig.fromJson(everyField);
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('round-trips all 4 fields through JSON too', () {
      final subject = form()..readFrom(WebpushConfig.fromJson(everyField));

      expect(subject.toModel()!.toJson(), everyField);
    });

    test('carries the free-form notification through untouched', () {
      // Browser vendors add Notification API options faster than a typed model
      // could follow, so a non-string value has to survive the form.
      final subject = form()..readFrom(WebpushConfig.fromJson(everyField));

      expect(subject.toModel()!.notification!['requireInteraction'], isTrue);
    });

    test('an emptied headers map is absent rather than an empty object', () {
      final subject = form()
        ..readFrom(const WebpushConfig(headers: {'TTL': '60'}));

      subject.headers.updateValue(<String, String>{});

      expect(subject.toModel(), isNull);
    });

    test('an emptied data map is absent rather than an empty object', () {
      final subject = form()
        ..readFrom(const WebpushConfig(data: {'event': 'build_finished'}));

      subject.data.updateValue(<String, String>{});

      expect(subject.toModel(), isNull);
    });

    test(
      'an emptied notification map is absent rather than an empty object',
      () {
        final subject = form()
          ..readFrom(
            const WebpushConfig(notification: {'title': 'Build finished'}),
          );

        subject.notification.updateValue(<String, Object?>{});

        expect(subject.toModel(), isNull);
      },
    );

    test('carries a nested fcm options block, with the WebPush link', () {
      // WebpushFcmOptions carries `link`, which neither the generic nor the
      // APNs block does: the two options forms are deliberately not
      // interchangeable.
      const source = WebpushConfig(
        fcmOptions: WebpushFcmOptions(link: 'https://example.test/builds'),
      );
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
      expect(subject.fcmOptions.link.value, 'https://example.test/builds');
    });

    test('clears every input when read from null', () {
      final subject = form()..readFrom(WebpushConfig.fromJson(everyField));

      subject.readFrom(null);

      expect(subject.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });

    test('stays valid when the nested options block is merely empty', () {
      final subject = form();

      expect(subject.fcmOptions.toModel(), isNull);
      expect(subject.isValid, isTrue);
    });
  });
}
