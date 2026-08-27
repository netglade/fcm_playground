import 'package:fcm_app/domains/telemetry/telemetry.dart';
import 'package:fcm_app/pages/telemetry/cubit/telemetry_state.dart';
import 'package:fcm_app/pages/telemetry/cubit/trace_timeline.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads the recent events and the latency matrix in one go.
///
/// One cubit for both tabs: they come from one server, and one refresh button is what
/// the page is for. A failure is expected rather than exceptional — the API is a local
/// process somebody has to have started — so it becomes a message on the screen instead
/// of an unhandled error.
class TelemetryCubit extends Cubit<TelemetryState> {
  TelemetryCubit(this._reader) : super(const TelemetryState());

  final TelemetryReader _reader;

  Future<void> load() async {
    emit(const TelemetryState());
    try {
      // Sequential rather than concurrent: two requests to a loopback development
      // server race for nothing, and a `Future.wait` would surface whichever failed
      // first while discarding the other's error.
      final events = await _reader.recentEvents();
      final latencies = await _reader.latencies();
      emit(
        TelemetryState(
          isLoading: false,
          traces: groupIntoTimelines(events),
          latencies: latencies,
        ),
      );
    } on TelemetryReaderException catch (error) {
      emit(TelemetryState(isLoading: false, error: error.message));
    }
  }
}
