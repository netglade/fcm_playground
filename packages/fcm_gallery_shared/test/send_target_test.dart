import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('toJson', () {
    test('writes the target at the top level, as FCM spells it', () {
      expect(const TokenTarget('abc').toJson(), {'token': 'abc'});
      expect(const TopicTarget('news').toJson(), {'topic': 'news'});
      expect(const ConditionTarget("'news' in topics").toJson(), {
        'condition': "'news' in topics",
      });
      expect(const AllDevicesTarget().toJson(), {'all_devices': true});
    });
  });

  group('readFrom', () {
    test('round-trips every variant', () {
      const targets = [
        TokenTarget('abc'),
        TopicTarget('news'),
        ConditionTarget("'news' in topics"),
        AllDevicesTarget(),
      ];
      for (final target in targets) {
        expect(SendTarget.readFrom(target.toJson()), target, reason: '$target');
      }
    });

    test('rejects a request with no target', () {
      // Defaulting to this device would send a topic broadcast to one phone and
      // look like it worked.
      expect(
        () => SendTarget.readFrom(<String, Object?>{'validate_only': false}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects two targets at once, naming both', () {
      expect(
        () => SendTarget.readFrom({'token': 'abc', 'topic': 'news'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('token'), contains('topic')),
          ),
        ),
      );
    });

    test('rejects a blank target value', () {
      expect(
        () => SendTarget.readFrom({'topic': '   '}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-string target value', () {
      expect(
        () => SendTarget.readFrom({'token': 42}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('has value equality, so a scenario can be compared', () {
    expect(const TopicTarget('news'), const TopicTarget('news'));
    expect(const TopicTarget('news'), isNot(const TopicTarget('beta')));
    expect(const TokenTarget('news'), isNot(const TopicTarget('news')));
  });
}
