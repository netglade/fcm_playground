import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('OpenedFrom', () {
    test('names all three states on the wire', () {
      // Pinned to literals: these strings reach the database in
      // TelemetryEvent.detail, and a renamed Dart identifier that silently changed
      // one would show up only as a matrix column that stops grouping.
      expect(
        {for (final value in OpenedFrom.values) value: value.wireName},
        equals({
          OpenedFrom.foreground: 'foreground',
          OpenedFrom.background: 'background',
          OpenedFrom.killed: 'killed',
        }),
      );
    });

    test('offers exactly the three states a tap can come from', () {
      // hasLength backs the word "exactly": without it a fourth value could be
      // appended and the map above would still be about the three checked here.
      expect(OpenedFrom.values, hasLength(3));
    });
  });

  group('OpenedFrom.fromWireName', () {
    test('round-trips every value through its wire name', () {
      for (final from in OpenedFrom.values) {
        expect(OpenedFrom.fromWireName(from.wireName), from);
      }
    });

    test('returns null for an unknown or absent name', () {
      expect(OpenedFrom.fromWireName('sideways'), isNull);
      expect(OpenedFrom.fromWireName(null), isNull);
    });
  });
}
