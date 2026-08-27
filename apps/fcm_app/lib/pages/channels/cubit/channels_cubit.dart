import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:fcm_app/pages/channels/cubit/channels_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The importance the page asks Android to give [immutabilityProbeChannelId].
///
/// Min, not merely lower: a change Android would refuse even in spirit makes the
/// refusal unambiguous when the page shows the value afterwards.
const _immutabilityProbeImportance = Importance.min;

/// Pairs the channels this app asks for with the ones Android actually holds.
///
/// A failure becomes a message rather than an unhandled error, the same as
/// `TelemetryCubit`: reading channels is a plugin call on a device, and a device
/// is entitled to say no.
class ChannelsCubit extends Cubit<ChannelsState> {
  ChannelsCubit(this._reader) : super(const ChannelsState());

  final NotificationChannelReader _reader;

  Future<void> load() async {
    emit(const ChannelsState());
    try {
      emit(ChannelsState(isLoading: false, comparisons: await _compare()));
    } on Object catch (error) {
      emit(ChannelsState(isLoading: false, error: '$error'));
    }
  }

  /// Performs d7: asks for a lower importance on `chat_v1`, then re-reads.
  ///
  /// The re-read is the demonstration. Asking without showing what the system
  /// holds afterwards would prove nothing.
  Future<void> tryLoweringChatV1() async {
    try {
      await _reader.attemptImportanceChange(
        immutabilityProbeChannelId,
        _immutabilityProbeImportance,
      );
      emit(ChannelsState(isLoading: false, comparisons: await _compare()));
    } on Object catch (error) {
      emit(ChannelsState(isLoading: false, error: '$error'));
    }
  }

  Future<List<ChannelComparison>> _compare() async {
    final actual = {
      for (final channel in await _reader.read()) channel.id: channel,
    };

    return [
      for (final requested in notificationChannels)
        ChannelComparison(requested: requested, actual: actual[requested.id]),
    ];
  }
}
