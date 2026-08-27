import 'dart:typed_data';

import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/channels/cubit/cubit.dart';
import 'package:fcm_app/pages/channels/widgets/channel_property_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One channel, requested against reported, with an extra button on the one
/// channel this app deliberately cannot fix.
///
/// A card, not a table row: each entry carries six properties plus a name and
/// description, which no row width holds without wrapping into this shape
/// anyway.
class ChannelCard extends StatelessWidget {
  const ChannelCard({required this.comparison, super.key});

  final ChannelComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    final requested = comparison.requested;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.channelName(requested.id),
              style: theme.textTheme.titleMedium,
            ),
            // Monospace and secondary — this is cross-referenced against
            // `android.notification.channel_id` in a payload, not read as
            // prose.
            Text(
              requested.id,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              t.channelDescription(requested.id),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 16),
            Row(
              children: [
                const SizedBox(width: 120),
                Expanded(
                  child: Text(
                    t.channels.requested,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    t.channels.reported,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            for (final row in _rows(t, comparison))
              ChannelPropertyRow(
                label: row.label,
                requested: row.requested,
                reported: row.reported,
                mismatches: row.mismatches,
              ),
            if (requested.id == immutabilityProbeChannelId) ...[
              const SizedBox(height: 8),
              Text(
                t.channels.immutability_hint,
                style: theme.textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: context.read<ChannelsCubit>().tryLoweringChatV1,
                  child: Text(t.channels.try_lower),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One property row's data: a label and the two values to compare.
///
/// Plain data, not a widget, so building the list stays a function — DCM's
/// `avoid-returning-widgets` would flag a helper returning a `Widget`.
typedef _RowData = ({
  String label,
  String requested,
  String reported,
  bool mismatches,
});

/// Every property row for [comparison], in card order: importance, sound,
/// vibration, DND bypass, group, badge.
///
/// An unregistered channel reports every row as `channels.not_registered` rather
/// than blank, so it never reads like a channel with default properties.
List<_RowData> _rows(Translations t, ChannelComparison comparison) {
  final requested = comparison.requested;
  final actual = comparison.actual;
  final registered = comparison.isRegistered;

  String reportedText(String Function() value) =>
      registered ? value() : t.channels.not_registered;

  return [
    (
      label: t.channels.importance,
      requested: requested.importance.name,
      reported: reportedText(() => actual!.importance.name),
      mismatches: !comparison.importanceMatches,
    ),
    (
      label: t.channels.sound,
      requested: _soundText(t, requested.sound?.sound),
      reported: reportedText(() => _soundText(t, actual!.sound?.sound)),
      // A null requested sound means "the system default", which is what every
      // channel but `custom_sound` asks for. Comparing it against the URI
      // Android reports back would flag all ten as disagreeing with a request
      // never made.
      mismatches:
          !registered ||
          (requested.sound != null &&
              requested.sound!.sound != actual?.sound?.sound),
    ),
    (
      label: t.channels.vibration,
      requested: _vibrationText(requested.vibrationPattern),
      reported: reportedText(() => _vibrationText(actual!.vibrationPattern)),
      mismatches:
          !registered ||
          !_sameVibration(requested.vibrationPattern, actual?.vibrationPattern),
    ),
    (
      label: t.channels.bypass_dnd,
      requested: '${requested.bypassDnd}',
      reported: reportedText(() => '${actual!.bypassDnd}'),
      mismatches: !comparison.bypassDndMatches,
    ),
    (
      label: t.channels.group_label,
      requested: _groupText(t, requested.groupId),
      reported: reportedText(() => _groupText(t, actual!.groupId)),
      mismatches: !registered || requested.groupId != actual?.groupId,
    ),
    (
      label: t.channels.badge,
      // AndroidNotificationChannel defaults showBadge to true and this app
      // never overrides it, so AppNotificationChannel has no field for it.
      requested: 'true',
      reported: reportedText(() => '${actual!.showBadge}'),
      mismatches: !registered || actual?.showBadge != true,
    ),
  ];
}

/// The URI Android reports for a channel registered with no explicit sound —
/// assigned by the plugin's Android side, not asked for here.
const _systemDefaultSoundUri = 'content://settings/system/notification_sound';

/// [sound] for display: a dash for none, a word for the platform default, or the
/// raw resource name.
String _soundText(Translations t, String? sound) {
  if (sound == null) {
    return '—';
  }
  if (sound == _systemDefaultSoundUri) {
    return t.channels.default_sound;
  }

  return sound;
}

String _vibrationText(Int64List? pattern) =>
    pattern == null ? '—' : pattern.toList().toString();

bool _sameVibration(Int64List? a, Int64List? b) {
  if (a == null || b == null) {
    return a == b;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

/// The chat group's translated heading when [groupId] names it, the raw id for
/// any other group this app might one day add, or a dash when there is none.
String _groupText(Translations t, String? groupId) => switch (groupId) {
  null => '—',
  chatChannelGroupId => t.chatChannelGroupName,
  final id => id,
};
