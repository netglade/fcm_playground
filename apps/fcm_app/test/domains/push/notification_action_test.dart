import 'package:fcm_app/domains/push/notification_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseNotificationActions', () {
    test('parses a pipe-separated list of id:Label pairs', () {
      final actions = parseNotificationActions('retry:Retry|open:Open build');

      expect(actions, [
        const NotificationAction('retry', 'Retry'),
        const NotificationAction('open', 'Open build'),
      ]);
    });

    test('trims whitespace around both halves of a pair', () {
      final actions = parseNotificationActions(' retry : Retry ');

      expect(actions, [const NotificationAction('retry', 'Retry')]);
    });

    test('keeps a label containing a colon, splitting on the first only', () {
      final actions = parseNotificationActions('open:Open: build 128');

      expect(
        actions,
        [const NotificationAction('open', 'Open: build 128')],
        reason:
            'the id cannot contain a colon but a human-readable label can, so '
            'the first colon is the separator and the rest is label',
      );
    });

    test('yields nothing for null, empty, or whitespace', () {
      expect(parseNotificationActions(null), isEmpty);
      expect(parseNotificationActions(''), isEmpty);
      expect(parseNotificationActions('   '), isEmpty);
    });

    test('drops a malformed pair and keeps the well-formed ones', () {
      final actions = parseNotificationActions('retry:Retry|nocolon|:blank|x:');

      expect(
        actions,
        [const NotificationAction('retry', 'Retry')],
        reason:
            'a bad actions string must cost the user the bad button, not the '
            'whole notification',
      );
    });

    test('keeps the first of two entries sharing an id', () {
      final actions = parseNotificationActions('retry:Retry|retry:Again');

      expect(
        actions,
        [const NotificationAction('retry', 'Retry')],
        reason:
            'two buttons reporting the same action id would make the press '
            'ambiguous on the way back',
      );
    });

    test('keeps at most three, because Android shows no more usefully', () {
      final actions = parseNotificationActions('a:A|b:B|c:C|d:D');

      expect(actions.map((action) => action.id), ['a', 'b', 'c']);
    });

    test('reads a trailing :input as a request for typed input', () {
      final actions = parseNotificationActions('reply:Reply:input');

      expect(actions, [
        const NotificationAction('reply', 'Reply', takesInput: true),
      ]);
    });

    test('leaves an action without the flag alone', () {
      final actions = parseNotificationActions('open:Open build');

      expect(actions.single.takesInput, isFalse);
    });

    test('mixes an input action and a plain one', () {
      final actions = parseNotificationActions('reply:Reply:input|mute:Mute');

      expect(actions.map((action) => action.id), ['reply', 'mute']);
      expect(actions.map((action) => action.takesInput), [true, false]);
    });

    test('keeps a colon-bearing label that does not end in the flag', () {
      final actions = parseNotificationActions('open:Open: build 128');

      expect(
        actions,
        [const NotificationAction('open', 'Open: build 128')],
        reason:
            'the flag is only the trailing segment when it is exactly `input`, '
            'so a label may still contain a colon as it always could',
      );
    });

    test('tolerates whitespace around the flag', () {
      final actions = parseNotificationActions('reply:Reply : input ');

      expect(actions, [
        const NotificationAction('reply', 'Reply', takesInput: true),
      ]);
    });

    test('drops an action whose label is only the flag', () {
      expect(
        parseNotificationActions('reply::input'),
        isEmpty,
        reason:
            'a button with no label is not a button, and the flag is not one '
            'either',
      );
    });
  });

  group('notificationActionLabel', () {
    test('returns the label the payload gave the id', () {
      expect(
        notificationActionLabel('retry:Retry|open:Open build', 'open'),
        'Open build',
      );
    });

    test('falls back to the id when the payload names no such action', () {
      expect(
        notificationActionLabel('retry:Retry', 'open'),
        'open',
        reason:
            'the stored press outlives the payload that produced it, so an id '
            'with no label must still render as something',
      );
    });
  });
}
