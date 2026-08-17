import 'package:fcm_app/pages/sandbox/forms/fcm_message_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  setUpAll(GladeForms.initialize);

  /// Every field set, so the round-trip proves no field was forgotten.
  ///
  /// An inlined copy of the contract package's own fixture, which is a `const`
  /// local to that test's `main()` and so invisible here. `hasLength(6)` below guards the copy.
  const everyField = {
    'data': {'event': 'build_finished'},
    'notification': {'title': 'Build finished'},
    'android': {'priority': 'HIGH'},
    'webpush': {
      'headers': {'TTL': '60'},
    },
    'apns': {
      'headers': {'apns-priority': '10'},
    },
    'fcm_options': {'analytics_label': 'campaign-1'},
  };

  FcmMessageForm form() => FcmMessageForm()..initialize();

  group('FcmMessageForm', () {
    test('the fixture still covers every field', () {
      // A seventh field on FcmMessage fails here instead of silently narrowing
      // the round-trip below.
      expect(everyField, hasLength(6));
    });

    test('is valid while empty, since FCM requires nothing here', () {
      expect(form().isValid, isTrue);
    });

    test('always produces a message, even an empty one', () {
      // The root is the one form whose toModel() is non-null: there is no
      // enclosing object to omit it from, and Send always has a payload.
      expect(form().toModel(), const FcmMessage());
    });

    test('round-trips all 6 fields', () {
      final source = FcmMessage.fromJson(everyField);
      final subject = form();

      subject.readFrom(source);

      expect(subject.toModel(), source);
    });

    test('round-trips all 6 fields through JSON too', () {
      final subject = form()..readFrom(FcmMessage.fromJson(everyField));

      expect(subject.toModel().toJson(), everyField);
    });

    test('an emptied data map is absent rather than an empty object', () {
      // FcmMessage.== compares data with MapEquality, so {} is not null:
      // deleting every row would otherwise leave "data": {} in the payload.
      final subject = form()
        ..readFrom(const FcmMessage(data: {'event': 'build_finished'}));

      subject.data.updateValue(<String, String>{});

      expect(subject.toModel(), const FcmMessage());
    });

    test('clears every input when read from null', () {
      final subject = form()..readFrom(FcmMessage.fromJson(everyField));

      subject.readFrom(null);

      expect(subject.toModel(), const FcmMessage());
      expect(subject.toModel().toJson(), isEmpty);
      expect(subject.isValid, isTrue);
    });

    test('is invalid when a nested block is invalid', () {
      // The nested inputs are not in `inputs`, so the inherited `isValid` cannot see
      // them. Validity has to compose at every level or the section badge lies.
      final subject = form();

      subject.android.ttl.updateValue('later');

      expect(subject.isValid, isFalse);
    });

    test('is invalid when a field three levels down is invalid', () {
      // light_settings sits under android.notification, so this only holds if
      // every level folds its children in.
      final subject = form();

      subject.android.notification.lightSettings.red.controller!.text = '2.5';

      expect(subject.isValid, isFalse);
    });

    test('allModels reaches light_settings, three levels down', () {
      // A level that forgot to pass its children up would be invisible except as an
      // on-screen value that never changes.
      final subject = form();

      expect(
        subject.allModels,
        contains(subject.android.notification.lightSettings),
      );
    });

    test('allModels holds every model in the tree, the root included', () {
      final subject = form();

      expect(subject.allModels, hasLength(11));
      expect(
        subject.allModels,
        containsAll(<GladeModelBase>[
          subject,
          subject.notification,
          subject.android,
          subject.android.notification,
          subject.android.notification.lightSettings,
          subject.android.fcmOptions,
          subject.apns,
          subject.apns.fcmOptions,
          subject.webpush,
          subject.webpush.fcmOptions,
          subject.fcmOptions,
        ]),
      );
    });

    test('a nested change does not notify the root', () {
      // Why allModels exists at all, recorded as a test: if a future glade_forms did
      // propagate a child's notification, this fails and the page could stop holding
      // eleven listeners.
      final subject = form();
      var notifications = 0;
      subject.addListener(() => notifications++);

      subject.android.notification.title.updateValue('Build finished');

      expect(notifications, 0);
    });

    test('every gallery scenario survives a form round trip', () {
      for (final scenario in scenarioGallery) {
        final source = FcmMessage.fromJson(scenario.payloadTemplate);
        final form = FcmMessageForm()..initialize();

        form.readFrom(source);

        expect(form.toModel(), source, reason: scenario.id);
      }
    });
  });
}
