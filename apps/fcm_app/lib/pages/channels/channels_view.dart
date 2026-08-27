import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/channels/cubit/cubit.dart';
import 'package:fcm_app/pages/channels/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the app asked Android for, against what Android actually reports back.
///
/// A comparison, not a listing: the cubit already lives above this widget —
/// unlike `TelemetryView`, which builds its own from a `reader`, this page reads
/// `ChannelsCubit` from `context`, the same way `SandboxView` does. Android
/// channel state changes underneath the app whenever the user edits a channel
/// in system settings, so the shell re-runs `load()` on every visit rather than
/// this widget owning a cubit whose staleness nobody would notice.
class ChannelsView extends StatelessWidget {
  const ChannelsView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: context.read<ChannelsCubit>().load,
            icon: const Icon(Icons.refresh),
            tooltip: t.channels.refresh,
          ),
        ),
        Expanded(
          child: BlocBuilder<ChannelsCubit, ChannelsState>(
            builder: (context, state) => switch (state) {
              ChannelsState(isLoading: true) => const Center(
                child: CircularProgressIndicator(),
              ),
              ChannelsState(error: final error?) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(error),
                ),
              ),
              // A plain scrolling `Column` rather than `ListView`: the catalogue is
              // fixed and short — eleven channels — so there is no list long enough
              // for `ListView`'s lazy building to earn its keep, and every card
              // stays mounted regardless of scroll position.
              ChannelsState(:final comparisons) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final comparison in comparisons)
                      ChannelCard(comparison: comparison),
                  ],
                ),
              ),
            },
          ),
        ),
      ],
    );
  }
}
