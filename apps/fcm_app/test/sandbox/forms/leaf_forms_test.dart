import 'package:fcm_app/sandbox/forms/apns_fcm_options_form.dart';
import 'package:fcm_app/sandbox/forms/fcm_notification_form.dart';
import 'package:fcm_app/sandbox/forms/fcm_options_form.dart';
import 'package:fcm_app/sandbox/forms/webpush_fcm_options_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  // Required once before any GladeModel is constructed — found in Task 1.
  setUpAll(GladeForms.initialize);

  group('FcmNotificationForm', () {
    test('is valid while empty, since FCM requires nothing here', () {
      final form = FcmNotificationForm()..initialize();

      expect(form.isValid, isTrue);
    });

    test('returns null when nothing is set, so the block is omitted', () {
      final form = FcmNotificationForm()..initialize();

      expect(form.toModel(), isNull);
    });

    test('round-trips a populated block', () {
      const source = FcmNotification(
        title: 'Build finished',
        body: 'Ready.',
        image: 'https://example.test/a.png',
      );
      final form = FcmNotificationForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });

    test('omits a field left empty rather than sending a blank string', () {
      final form = FcmNotificationForm()..initialize();

      form.readFrom(const FcmNotification(title: 'Only a title'));

      expect(form.toModel(), const FcmNotification(title: 'Only a title'));
      expect(form.toModel()!.body, isNull);
    });

    test('clears every input when read from null', () {
      final form = FcmNotificationForm()..initialize();
      form.readFrom(const FcmNotification(title: 'set'));

      form.readFrom(null);

      expect(form.toModel(), isNull);
    });
  });

  group('FcmOptionsForm', () {
    test('is valid while empty', () {
      expect((FcmOptionsForm()..initialize()).isValid, isTrue);
    });

    test('returns null when nothing is set', () {
      expect((FcmOptionsForm()..initialize()).toModel(), isNull);
    });

    test('round-trips its only field', () {
      const source = FcmOptions(analyticsLabel: 'campaign-1');
      final form = FcmOptionsForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });

    test('clears when read from null', () {
      final form = FcmOptionsForm()
        ..initialize()
        ..readFrom(const FcmOptions(analyticsLabel: 'set'));

      form.readFrom(null);

      expect(form.toModel(), isNull);
    });
  });

  group('ApnsFcmOptionsForm', () {
    test('is valid while empty', () {
      expect((ApnsFcmOptionsForm()..initialize()).isValid, isTrue);
    });

    test('returns null when nothing is set', () {
      expect((ApnsFcmOptionsForm()..initialize()).toModel(), isNull);
    });

    test('round-trips the image APNs alone accepts', () {
      const source = ApnsFcmOptions(
        image: 'https://example.test/a.png',
        analyticsLabel: 'campaign-1',
      );
      final form = ApnsFcmOptionsForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });

    test('clears when read from null', () {
      final form = ApnsFcmOptionsForm()
        ..initialize()
        ..readFrom(const ApnsFcmOptions(image: 'set'));

      form.readFrom(null);

      expect(form.toModel(), isNull);
    });
  });

  group('WebpushFcmOptionsForm', () {
    test('is valid while empty', () {
      expect((WebpushFcmOptionsForm()..initialize()).isValid, isTrue);
    });

    test('returns null when nothing is set', () {
      expect((WebpushFcmOptionsForm()..initialize()).toModel(), isNull);
    });

    test('round-trips the link WebPush alone accepts', () {
      const source = WebpushFcmOptions(
        link: 'https://example.test/open',
        analyticsLabel: 'campaign-1',
      );
      final form = WebpushFcmOptionsForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });

    test('clears when read from null', () {
      final form = WebpushFcmOptionsForm()
        ..initialize()
        ..readFrom(const WebpushFcmOptions(link: 'set'));

      form.readFrom(null);

      expect(form.toModel(), isNull);
    });
  });

  group('the three options forms are not interchangeable', () {
    test('each carries only the fields its platform accepts', () {
      // The generic block accepts analytics_label alone; APNs adds image and
      // WebPush adds link. One shared form would let a field through on a
      // platform that rejects it, which is why the typed model has three.
      final apns = ApnsFcmOptionsForm()..initialize();
      final webpush = WebpushFcmOptionsForm()..initialize();

      apns.readFrom(const ApnsFcmOptions(image: 'https://example.test/a.png'));
      webpush.readFrom(
        const WebpushFcmOptions(link: 'https://example.test/open'),
      );

      expect(apns.toModel()!.image, isNotNull);
      expect(webpush.toModel()!.link, isNotNull);
    });
  });
}
