import 'package:fcm_app/domains/notifications/data_sources/notification_channels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('registerNotificationChannels', () {
    test('creates the chat group before any channel that belongs to it', () async {
      await registerNotificationChannels(FlutterLocalNotificationsPlugin());

      final groupIndex = calls.indexWhere(
        (c) => c.method == 'createNotificationChannelGroup',
      );
      final firstChannelIndex = calls.indexWhere(
        (c) => c.method == 'createNotificationChannel',
      );

      // Android files a channel under a group that does not exist yet by
      // dropping the grouping silently, so the order is load-bearing.
      expect(groupIndex, isNonNegative);
      expect(groupIndex, lessThan(firstChannelIndex));
    });

    test('creates every channel in the table', () async {
      await registerNotificationChannels(FlutterLocalNotificationsPlugin());

      final created = calls
          .where((c) => c.method == 'createNotificationChannel')
          .map((c) => (c.arguments as Map)['id'])
          .toSet();

      expect(created, {for (final c in notificationChannels) c.id});
    });

    test('sends the properties the scenarios turn on', () async {
      await registerNotificationChannels(FlutterLocalNotificationsPlugin());

      Map<Object?, Object?> argumentsFor(String id) =>
          calls
                  .firstWhere(
                    (c) =>
                        c.method == 'createNotificationChannel' &&
                        (c.arguments as Map)['id'] == id,
                  )
                  .arguments
              as Map<Object?, Object?>;

      expect(argumentsFor('dnd_bypass')['bypassDnd'], isTrue);
      expect(argumentsFor('importance_min')['importance'], Importance.min.value);
      expect(argumentsFor('chat_v1')['groupId'], chatChannelGroupId);
      expect(argumentsFor('vibration_pattern')['vibrationPattern'], isNotNull);
    });

    test('names every channel from the translations', () async {
      await registerNotificationChannels(FlutterLocalNotificationsPlugin());

      final names = calls
          .where((c) => c.method == 'createNotificationChannel')
          .map((c) => (c.arguments as Map)['name'] as String);

      // The failure this catches is a channel registered under its raw id
      // because a CSV row was missed — legible in system settings as
      // "importance_min" rather than a sentence.
      expect(names, everyElement(isNotEmpty));
      expect(names, isNot(contains('importance_min')));
    });
  });
}
