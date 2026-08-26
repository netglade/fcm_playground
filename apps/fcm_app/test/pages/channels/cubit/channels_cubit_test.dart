import 'package:fcm_app/domains/notifications/data_sources/notification_channels.dart';
import 'package:fcm_app/domains/notifications/entities/notification_channel_reader.dart';
import 'package:fcm_app/pages/channels/cubit/channels_cubit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// A reader whose answers the test dictates, and which records what it was asked.
class _FakeReader implements NotificationChannelReader {
  _FakeReader(this._channels);

  final List<AndroidNotificationChannel> _channels;
  final attempts = <(String, Importance)>[];
  Object? failWith;

  @override
  Future<List<AndroidNotificationChannel>> read() async {
    if (failWith case final error?) throw error;

    return _channels;
  }

  @override
  Future<void> attemptImportanceChange(String id, Importance importance) async {
    attempts.add((id, importance));
    // Android's actual behaviour: the request is accepted and the importance
    // does not move. The fake must not be kinder than the platform.
  }
}

AndroidNotificationChannel _system(
  String id, {
  Importance importance = Importance.high,
  bool bypassDnd = false,
}) => AndroidNotificationChannel(
  id,
  'name',
  importance: importance,
  bypassDnd: bypassDnd,
);

void main() {
  group('ChannelsCubit', () {
    test('pairs every requested channel with what the system reports', () async {
      final cubit = ChannelsCubit(
        _FakeReader([
          for (final channel in notificationChannels)
            _system(channel.id, importance: channel.importance),
        ]),
      );

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.comparisons, hasLength(notificationChannels.length));
      expect(
        cubit.state.comparisons.every((c) => c.importanceMatches),
        isTrue,
      );
    });

    test('marks a channel the system does not have', () async {
      final cubit = ChannelsCubit(_FakeReader([]));

      await cubit.load();

      expect(cubit.state.comparisons.first.isRegistered, isFalse);
      expect(cubit.state.comparisons.first.importanceMatches, isFalse);
    });

    test('reports bypassDnd asked for but not granted', () async {
      final requested = channelById('dnd_bypass')!;
      final cubit = ChannelsCubit(
        _FakeReader([_system('dnd_bypass', importance: requested.importance)]),
      );

      await cubit.load();

      final dnd = cubit.state.comparisons.firstWhere(
        (c) => c.requested.id == 'dnd_bypass',
      );
      // h1 made visible: the app asked for true, the system answered false.
      expect(dnd.requested.bypassDnd, isTrue);
      expect(dnd.actual?.bypassDnd, isFalse);
      expect(dnd.bypassDndMatches, isFalse);
    });

    test('asks to lower chat_v1 and re-reads afterwards', () async {
      final reader = _FakeReader([
        _system('chat_v1', importance: Importance.defaultImportance),
      ]);
      final cubit = ChannelsCubit(reader);

      await cubit.tryLoweringChatV1();

      expect(reader.attempts, [('chat_v1', Importance.min)]);
      // The re-read is the point: d7 is only demonstrated if the page shows the
      // value it holds *after* the attempt.
      final chat = cubit.state.comparisons.firstWhere(
        (c) => c.requested.id == 'chat_v1',
      );
      expect(chat.actual?.importance, Importance.defaultImportance);
    });

    test('turns a read failure into a message rather than an error', () async {
      final cubit = ChannelsCubit(_FakeReader([])..failWith = Exception('nope'));

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.comparisons, isEmpty);
    });
  });
}
