import 'dart:typed_data';

import 'package:fcm_app/domains/notifications/notification_appearance.dart';
import 'package:fcm_app/domains/push/push_message.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

PushMessage message({
  String title = 'Release notes',
  String body = 'A long body.',
  Map<String, String> data = const {},
}) => PushMessage(
  id: 'msg-1',
  title: title,
  body: body,
  sentAt: DateTime.utc(2026, 9, 4, 9),
  data: data,
);

final _bytes = Uint8List.fromList([1, 2, 3]);

void main() {
  group('appearanceFor', () {
    test('defaults to big text, so every drawn notification expands', () {
      final appearance = appearanceFor(message());

      expect(appearance.style, isA<BigTextStyleInformation>());
      final style = appearance.style as BigTextStyleInformation;
      expect(style.bigText, 'A long body.');
      expect(style.contentTitle, 'Release notes');
      expect(appearance.largeIcon, isNull);
      expect(appearance.showProgress, isFalse);
    });

    test(
      'an unknown style name falls back to big text rather than throwing',
      () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'kaleidoscope'}),
        );

        expect(appearance.style, isA<BigTextStyleInformation>());
      },
    );

    group('big_picture', () {
      test('wraps the downloaded bytes', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'big_picture'}),
          picture: _bytes,
        );

        expect(appearance.style, isA<BigPictureStyleInformation>());
        final style = appearance.style as BigPictureStyleInformation;
        expect(style.bigPicture, isA<ByteArrayAndroidBitmap>());
        expect(style.contentTitle, 'Release notes');
      });

      // The download is allowed to fail — 404, timeout, oversized — and the
      // notification still has to arrive. Losing the picture is the cost;
      // losing the notification would not be.
      test('falls back to big text when no bytes arrived', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'big_picture'}),
        );

        expect(appearance.style, isA<BigTextStyleInformation>());
      });
    });

    group('large_icon', () {
      test('is a field, not a style, so big text still applies', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'large_icon'}),
          largeIcon: _bytes,
        );

        expect(appearance.largeIcon, isA<ByteArrayAndroidBitmap>());
        expect(appearance.style, isA<BigTextStyleInformation>());
      });

      test('stays null when no bytes arrived', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'large_icon'}),
        );

        expect(appearance.largeIcon, isNull);
      });
    });

    group('inbox', () {
      test('splits the lines on the pipe', () {
        final appearance = appearanceFor(
          message(
            title: '3 new builds',
            data: {
              pushStyleKey: 'inbox',
              pushLinesKey:
                  'build 128 passed|build 127 passed|build 126 failed',
            },
          ),
        );

        expect(appearance.style, isA<InboxStyleInformation>());
        final style = appearance.style as InboxStyleInformation;
        expect(style.lines, [
          'build 128 passed',
          'build 127 passed',
          'build 126 failed',
        ]);
        expect(style.contentTitle, '3 new builds');
      });

      test('drops blank entries instead of drawing empty rows', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'inbox', pushLinesKey: 'one||  |two'}),
        );

        expect((appearance.style as InboxStyleInformation).lines, [
          'one',
          'two',
        ]);
      });

      test('falls back to big text when there are no usable lines', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'inbox', pushLinesKey: '  |  '}),
        );

        expect(appearance.style, isA<BigTextStyleInformation>());
      });
    });

    group('messaging', () {
      test('reads sender and text from each entry', () {
        final appearance = appearanceFor(
          message(
            data: {
              pushStyleKey: 'messaging',
              pushConversationKey: 'Release team',
              pushMessagesKey: 'Ada:ready when you are|Grace:shipping now',
            },
          ),
        );

        expect(appearance.style, isA<MessagingStyleInformation>());
        final style = appearance.style as MessagingStyleInformation;
        expect(style.conversationTitle, 'Release team');
        expect(style.messages, hasLength(2));
        expect(style.messages!.first.person?.name, 'Ada');
        expect(style.messages!.first.text, 'ready when you are');
      });

      // Only the first colon separates the sender, the same rule
      // `parseNotificationActions` follows, so a message may contain one.
      test('keeps a colon inside the message text', () {
        final appearance = appearanceFor(
          message(
            data: {
              pushStyleKey: 'messaging',
              pushMessagesKey: 'Ada:build 128: green',
            },
          ),
        );

        final style = appearance.style as MessagingStyleInformation;
        expect(style.messages!.single.text, 'build 128: green');
      });

      test('skips an entry with no sender rather than losing the rest', () {
        final appearance = appearanceFor(
          message(
            data: {
              pushStyleKey: 'messaging',
              pushMessagesKey: 'no sender here|Ada:fine',
            },
          ),
        );

        final style = appearance.style as MessagingStyleInformation;
        expect(style.messages, hasLength(1));
        expect(style.messages!.single.person?.name, 'Ada');
      });

      // Nothing in the payload says when each message was sent, and inventing
      // per-message times would put a false ordering on screen.
      test('stamps every message with the push time', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'messaging', pushMessagesKey: 'Ada:hi'}),
        );

        final style = appearance.style as MessagingStyleInformation;
        expect(style.messages!.single.timestamp, DateTime.utc(2026, 9, 4, 9));
      });

      test('falls back to big text when no entry parses', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'messaging', pushMessagesKey: 'nope'}),
        );

        expect(appearance.style, isA<BigTextStyleInformation>());
      });
    });

    group('progress', () {
      test('reads the two numbers off the payload', () {
        final appearance = appearanceFor(
          message(
            data: {
              pushStyleKey: 'progress',
              pushProgressKey: '40',
              pushMaxProgressKey: '100',
            },
          ),
        );

        expect(appearance.showProgress, isTrue);
        expect(appearance.progress, 40);
        expect(appearance.maxProgress, 100);
        expect(appearance.style, isA<BigTextStyleInformation>());
      });

      // A bar drawn from a number nobody sent would be a made-up figure, so an
      // unreadable value costs the bar rather than guessing at one.
      test('shows no bar when a number will not parse', () {
        final appearance = appearanceFor(
          message(
            data: {
              pushStyleKey: 'progress',
              pushProgressKey: 'soon',
              pushMaxProgressKey: '100',
            },
          ),
        );

        expect(appearance.showProgress, isFalse);
      });

      test('shows no bar when max is missing', () {
        final appearance = appearanceFor(
          message(data: {pushStyleKey: 'progress', pushProgressKey: '40'}),
        );

        expect(appearance.showProgress, isFalse);
      });
    });
  });
}
