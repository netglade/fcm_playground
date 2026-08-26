import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domains/notifications/data_sources/notification_channels.dart';
import '../../../i18n/channel_text.dart';
import '../../../i18n/translations.g.dart';
import '../cubit/channels_cubit.dart';
import '../cubit/channels_state.dart';
import 'channel_property_row.dart';

/// The channel `d7` demonstrates on: importance is asked to change, and the
/// card is where the refusal becomes visible.
const _immutabilityProbeChannelId = 'chat_v1';

/// One channel, requested against reported, with an extra button on the one
/// channel this app deliberately cannot fix.
///
/// A card rather than a table row: `notificationChannels` is a short, fixed
/// list, and each entry carries six properties plus a name and description —
/// there is no width a single table row could hold that in without wrapping
/// back into exactly this shape.
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
            if (requested.id == _immutabilityProbeChannelId) ...[
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
/// Plain data rather than a widget, so building the list stays a function
/// [ChannelCard] can call from its `children`, not a second widget in this file
/// — DCM's `avoid-returning-widgets` rule would flag a helper that handed back
/// a `Widget` directly.
typedef _RowData = ({
  String label,
  String requested,
  String reported,
  bool mismatches,
});

/// Every property row for [comparison], in the fixed order the card lists them:
/// importance, sound, vibration, DND bypass, group, badge.
///
/// A channel the system does not hold reports every row as
/// `channels.not_registered` rather than blank, so a missing channel and a
/// channel with merely-default properties never read the same.
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
      requested: _soundText(requested.sound?.sound),
      reported: reportedText(() => _soundText(actual!.sound?.sound)),
      mismatches: !registered || requested.sound?.sound != actual?.sound?.sound,
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
      // AndroidNotificationChannel defaults showBadge to true, and this app
      // never overrides it — AppNotificationChannel has no field for it because
      // there is nothing to ask for beyond that default.
      requested: 'true',
      reported: reportedText(() => '${actual!.showBadge}'),
      mismatches: !registered || actual?.showBadge != true,
    ),
  ];
}

String _soundText(String? sound) => sound ?? '—';

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
