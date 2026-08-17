import 'package:fcm_app/pages/runs/widgets/run_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats a UTC instant as HH:MM:SS UTC', () {
    expect(runTime(DateTime.utc(2026, 8, 17, 9, 5, 30)), '09:05:30 UTC');
  });

  test('converts to UTC before reading fields, whatever it is handed', () {
    // Every DTO this reads normalises to UTC in its own constructor, so this
    // never happens in practice — but the label says "UTC" unconditionally,
    // and a non-UTC `DateTime` would make that label a lie if `runTime` read
    // its fields as-is instead of converting first. This does not depend on
    // the test machine's own timezone: whatever `.toLocal()` produces here,
    // `runTime` must answer exactly as if `.toUtc()` had been called first.
    final instant = DateTime.utc(2026, 8, 17, 9, 5, 30);

    expect(runTime(instant.toLocal()), runTime(instant));
  });
}
