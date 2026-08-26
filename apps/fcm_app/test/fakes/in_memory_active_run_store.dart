import 'package:fcm_app/domains/runs/active_run_store.dart';

/// An [ActiveRunStore] in a field, so a cubit test needs no preferences platform.
class InMemoryActiveRunStore implements ActiveRunStore {
  String? _runId;

  @override
  Future<String?> activeRunId() async => _runId;

  @override
  Future<void> setActiveRunId(String runId) async => _runId = runId;

  @override
  Future<void> clear() async => _runId = null;
}
