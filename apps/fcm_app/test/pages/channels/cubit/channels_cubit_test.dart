import 'package:fcm_app/domains/notifications/notification_channels.dart';
import 'package:fcm_app/pages/channels/cubit/channels_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_channel_reader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  group('ChannelsCubit', () {
    test(
      'pairs every requested channel with what the system reports',
      () async {
        final cubit = ChannelsCubit(
          FakeChannelReader([
            for (final channel in notificationChannels)
              systemChannel(channel.id, importance: channel.importance),
          ]),
        );

        await cubit.load();

        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.comparisons, hasLength(notificationChannels.length));
        expect(
          cubit.state.comparisons.every((c) => c.importanceMatches),
          isTrue,
        );
      },
    );

    test('marks a channel the system does not have', () async {
      final cubit = ChannelsCubit(FakeChannelReader([]));

      await cubit.load();

      expect(cubit.state.comparisons.first.isRegistered, isFalse);
      expect(cubit.state.comparisons.first.importanceMatches, isFalse);
    });

    test('reports bypassDnd asked for but not granted', () async {
      final requested = channelById('dnd_bypass')!;
      final cubit = ChannelsCubit(
        FakeChannelReader([
          systemChannel('dnd_bypass', importance: requested.importance),
        ]),
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
      final reader = FakeChannelReader([
        systemChannel('chat_v1', importance: Importance.defaultImportance),
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
      final cubit = ChannelsCubit(
        FakeChannelReader([])..failWith = Exception('nope'),
      );

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.comparisons, isEmpty);
    });
  });
}
