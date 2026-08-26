import 'package:fcm_app/domains/notifications/data_sources/notification_channels.dart';
import 'package:fcm_app/domains/notifications/entities/notification_content.dart';
import 'package:fcm_app/i18n/channel_text.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every `channel_id` named by a scenario this app is expected to serve.
///
/// Scenarios blocked by some other unbuilt need are skipped: `f8_full_screen_intent`
/// names `calls` and `g1_group_summary` names `builds`, and both belong to the
/// interaction sub-project. Guessing their importance here would be worse than not
/// having them — Android freezes a channel's importance at creation, so a wrong guess
/// is permanent on every device that ran it.
///
/// This ratchets rather than going stale: when interaction lands and drops that need,
/// both scenarios re-enter this set and the guard demands their channels.
Set<String> _channelIdsInCatalogue() {
  final ids = <String>{};
  for (final scenario in scenarioGallery) {
    if (scenario.needs.any((need) => need != ScenarioNeed.channels)) continue;

    final android = scenario.payloadTemplate['android'];
    if (android is! Map) continue;
    final notification = android['notification'];
    if (notification is! Map) continue;
    final id = notification['channel_id'];
    if (id is String) ids.add(id);
  }

  return ids;
}

void main() {
  group('the channel table', () {
    test('holds every channel the catalogue sends to', () {
      final registered = {for (final c in notificationChannels) c.id};

      // The guard this table exists for: add a scenario naming a new channel
      // and this fails until the channel is defined, rather than the scenario
      // silently falling back to the default at run time.
      expect(_channelIdsInCatalogue().difference(registered), isEmpty);
    });

    test('keeps the manifest default as its first entry', () {
      expect(defaultNotificationChannel.id, notificationChannelId);
      expect(defaultNotificationChannel.importance, Importance.high);
    });

    test('gives every entry a distinct id', () {
      final ids = notificationChannels.map((c) => c.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('files both chat channels under one group, with frozen importances', () {
      final v1 = channelById('chat_v1')!;
      final v2 = channelById('chat_v2')!;

      expect(v1.groupId, chatChannelGroupId);
      expect(v2.groupId, chatChannelGroupId);
      // d7's whole point: the two differ in the one property Android will not
      // let the app change after creation.
      expect(v1.importance, isNot(v2.importance));
    });

    test('carries the properties h1 and h2 turn on', () {
      expect(channelById('dnd_bypass')!.bypassDnd, isTrue);
      expect(
        channelById('alarms')!.audioAttributesUsage,
        AudioAttributesUsage.alarm,
      );
    });

    test('resolves an unknown or absent id to null', () {
      expect(channelById('no_such_channel'), isNull);
      expect(channelById(null), isNull);
    });
  });

  group('channel copy', () {
    test('every channel is named and described in both languages', () {
      for (final locale in [AppLocale.en, AppLocale.cs]) {
        final t = locale.buildSync();
        for (final channel in notificationChannels) {
          expect(
            t.channelName(channel.id),
            isNotEmpty,
            reason: '${channel.id} has no name in ${locale.languageCode}',
          );
          expect(
            t.channelDescription(channel.id),
            isNotEmpty,
            reason: '${channel.id} has no description in ${locale.languageCode}',
          );
        }
        expect(t.chatChannelGroupName, isNotEmpty);
      }
    });
  });
}
