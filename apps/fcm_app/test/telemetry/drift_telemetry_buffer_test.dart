import 'package:drift/native.dart';
import 'package:fcm_app/telemetry/drift_telemetry_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'system_sqlite.dart';

void main() {
  late DriftTelemetryBuffer buffer;

  // `flutter test` is a Dart VM, not a device, so the plugin-bundled SQLite is
  // not there and the package's default library name is not on this machine.
  setUpAll(useSystemSqlite);

  setUp(() => buffer = DriftTelemetryBuffer(NativeDatabase.memory()));

  tearDown(() => buffer.close());

  // The point of this test is the toolchain, not the schema: it proves that the
  // committed generated code compiles against the runtime, that a Drift
  // database opens under `flutter test` rather than only on a device, and that
  // a write is readable back. Task 11's behaviour goes on top of that.
  test('opens in memory and round-trips one row', () async {
    await buffer.recordTrace('trace-1');

    expect(await buffer.traces(), ['trace-1']);
  });
}
