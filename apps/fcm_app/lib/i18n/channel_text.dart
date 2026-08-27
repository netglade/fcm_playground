import 'package:fcm_app/i18n/translations.g.dart';

/// A channel's user-visible copy, by channel id.
///
/// The same thin typed face over slang's flat map that `ScenarioText` is, and for
/// the same reason: the map is `dynamic`, and naming the two shapes this app asks
/// of it keeps the casts out of the callers.
///
/// Android shows both strings in system settings, so both are translated. Ids are
/// already snake_case, so unlike `scenarioNeedLabel` there is nothing to convert
/// for slang's `key_case: snake`.
extension ChannelText on Translations {
  String channelName(String id) => this['channels.$id.name'] as String;

  String channelDescription(String id) =>
      this['channels.$id.description'] as String;

  /// The heading the two chat channels appear under.
  String get chatChannelGroupName => this['channels.group.chat.name'] as String;
}
