import 'package:fcm_app/domains/notifications/data_sources/notification_reply.dart';
import 'package:fcm_app/domains/push/entities/pending_reply.dart';
import 'package:fcm_app/domains/settings/data_sources/shared_preferences_locale_store.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // `LocaleSettings` is global process state; a test that leaves it on Czech
  // would break whichever English-asserting test the runner reaches next.
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('draws the reply notification in the stored language', () async {
    // The third isolate has no BuildContext and no widget tree, so the store is
    // the only place the locale can come from.
    SharedPreferences.setMockInitialValues({localeKey: 'cs'});

    final storedLocale = await const SharedPreferencesLocaleStore().read();
    LocaleSettings.setLocaleSync(storedLocale!);

    expect(t.reply.sending, 'Odesílám…');
    expect(t.reply.sent, 'Odesláno');
    expect(t.reply.not_sent, 'Neodesláno');
  });

  group('replyFrom', () {
    test(
      'takes the message id from the payload and the text from the input',
      () {
        final reply = replyFrom(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'msg-1',
            actionId: 'reply',
            input: 'ready when you are',
          ),
        );

        expect(reply, const PendingReply('msg-1', 'ready when you are'));
      },
    );

    test('carries the id of the action the reply was pressed through', () {
      final reply = replyFrom(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          payload: 'msg-1',
          actionId: 'note',
          input: 'ready when you are',
        ),
      );

      expect(
        reply?.actionId,
        'note',
        reason:
            'telemetry records the pressed action\'s own id, not a literal '
            'that is only ever right for one of them',
      );
    });

    test('keeps an empty reply, which is a thing a user can send', () {
      final reply = replyFrom(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          payload: 'msg-1',
          actionId: 'reply',
          input: '',
        ),
      );

      expect(reply?.text, '');
    });

    test('ignores a response carrying no input at all', () {
      expect(
        replyFrom(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'msg-1',
            actionId: 'mute',
          ),
        ),
        isNull,
        reason:
            'a plain action reaches the main isolate and is answered there; '
            'this isolate only exists for the typed kind',
      );
    });

    test('ignores a response with no payload to attach the reply to', () {
      expect(
        replyFrom(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: 'reply',
            input: 'orphan',
          ),
        ),
        isNull,
      );
    });
  });
}
