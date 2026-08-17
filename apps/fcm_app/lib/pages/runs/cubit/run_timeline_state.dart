import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// One run, as the timeline page reads it.
///
/// Two states compare equal only when every item has the same state *and* the
/// same events, by type and count — not just the same state. The reload
/// button on this page exists to pick up events that arrived since the last
/// load: for a killed app, an arrival is buffered on the device and only
/// reaches the API at the next launch, so an item can gain a `received_bg`
/// event while its own state stays `sent`. A comparison blind to events would
/// leave that reload button doing nothing when it matters most.
class RunTimelineState {
  const RunTimelineState({this.isLoading = true, this.run, this.error});

  final bool isLoading;

  final ScheduledRun? run;

  final String? error;

  @override
  bool operator ==(Object other) =>
      other is RunTimelineState &&
      isLoading == other.isLoading &&
      error == other.error &&
      run?.id == other.run?.id &&
      _fingerprint(run) == _fingerprint(other.run);

  @override
  int get hashCode => Object.hash(isLoading, error, run?.id, _fingerprint(run));
}

/// Each item's state plus its events' types, as one string, so a reload that
/// changed either redraws while one that changed nothing does not.
String _fingerprint(ScheduledRun? run) =>
    run?.items
        .map(
          (item) =>
              '${item.state.wireName}:'
              '${item.events.map((e) => e.type.wireName).join('|')}',
        )
        .join(',') ??
    '';
