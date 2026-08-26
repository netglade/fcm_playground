import 'package:fcm_app/domains/runs/countdown_screen.dart';

/// A [CountdownScreen] that records what it was asked to do.
class RecordingCountdownScreen implements CountdownScreen {
  final calls = <String>[];

  @override
  Future<void> keepAwake() async => calls.add('keepAwake');

  @override
  Future<void> dim() async => calls.add('dim');

  @override
  Future<void> release() async => calls.add('release');

  @override
  Future<void> openBatterySettings() async => calls.add('battery');
}
