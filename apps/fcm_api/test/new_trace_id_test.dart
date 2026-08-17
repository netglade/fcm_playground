import 'package:fcm_api/fcm_api.dart';
import 'package:test/test.dart';

void main() {
  group('newTraceId', () {
    test('never returns the same id twice', () {
      // Two sends sharing an id would merge into one row in the latency table,
      // and the second would read as a message that never arrived.
      final ids = {for (var i = 0; i < 1000; i++) newTraceId()};

      expect(ids, hasLength(1000));
    });

    test('is safe to carry in an FCM data value', () {
      // It travels as a `data` string and comes back in a JSON event body, so
      // anything needing escaping is a liability. Hex and dashes only.
      expect(newTraceId(), matches(RegExp(r'^[0-9a-f]+-[0-9a-f]{8}$')));
    });
  });
}
