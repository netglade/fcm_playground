import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationEvent', () {
    test('wire names are unique, so fromWireName is unambiguous', () {
      final names = NotificationEvent.values.map((e) => e.wireName).toSet();

      expect(names, hasLength(NotificationEvent.values.length));
    });

    test('every value round-trips through its wire name', () {
      for (final event in NotificationEvent.values) {
        expect(NotificationEvent.fromWireName(event.wireName), event);
      }
    });

    test('wire names are snake_case, not the Dart identifier', () {
      expect(NotificationEvent.chatMessage.wireName, 'chat_message');
      expect(NotificationEvent.buildFinished.wireName, 'build_finished');
      expect(NotificationEvent.silentSync.wireName, 'silent_sync');
    });

    test('an unrecognised wire name resolves to null rather than throwing', () {
      expect(NotificationEvent.fromWireName('from_the_future'), isNull);
    });
  });
}
