import 'package:fcm_app/domains/notifications/background_notification_draw.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldDrawInBackground', () {
    test('draws for a data-only message, which FCM will not draw', () {
      const message = RemoteMessage(data: {'title': 'Build failed'});

      expect(shouldDrawInBackground(message), isTrue);
    });

    test('leaves a message carrying a notification block to FCM', () {
      const message = RemoteMessage(
        data: {'actions': 'retry:Retry'},
        notification: RemoteNotification(title: 'Build failed'),
      );

      expect(
        shouldDrawInBackground(message),
        isFalse,
        reason:
            'FCM has already drawn a tray entry for it, and drawing a second '
            'beside it would give the user two notifications for one push',
      );
    });
  });
}
