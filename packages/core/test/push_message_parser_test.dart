import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  const parser = PushMessageParser();

  Map<String, Object?> validPayload({
    Map<String, Object?> overrides = const {},
  }) => {
    'id': 'msg-1',
    'title': 'Build finished',
    'body': 'Release 1.0.0 is ready.',
    'sentAt': '2026-08-06T09:30:00Z',
    ...overrides,
  };

  group('PushMessageParser.parse', () {
    test('maps a well-formed payload onto a PushMessage', () {
      final message = parser.parse(validPayload());

      expect(message.id, 'msg-1');
      expect(message.title, 'Build finished');
      expect(message.body, 'Release 1.0.0 is ready.');
      expect(message.sentAt, DateTime.utc(2026, 8, 6, 9, 30));
      expect(message.data, isEmpty);
    });

    test('normalises the timestamp to UTC', () {
      final message = parser.parse(
        validPayload(overrides: {'sentAt': '2026-08-06T11:30:00+02:00'}),
      );

      expect(message.sentAt.isUtc, isTrue);
      expect(message.sentAt, DateTime.utc(2026, 8, 6, 9, 30));
    });

    test('passes non-reserved keys through as data', () {
      final message = parser.parse(
        validPayload(overrides: {'deepLink': '/builds/42', 'retries': 3}),
      );

      expect(message.data, {'deepLink': '/builds/42', 'retries': '3'});
    });

    test('returns an unmodifiable data map', () {
      final message = parser.parse(
        validPayload(overrides: {'deepLink': '/builds/42'}),
      );

      expect(() => message.data['injected'] = 'nope', throwsUnsupportedError);
    });

    for (final field in PushMessageParser.requiredKeys) {
      test('throws when $field is missing', () {
        final payload = validPayload()..remove(field);

        expect(
          () => parser.parse(payload),
          throwsA(
            isA<PushMessageFormatException>()
                .having((e) => e.field, 'field', field)
                .having((e) => e.reason, 'reason', 'missing'),
          ),
        );
      });

      test('throws when $field is blank', () {
        expect(
          () => parser.parse(validPayload(overrides: {field: '   '})),
          throwsA(
            isA<PushMessageFormatException>().having(
              (e) => e.field,
              'field',
              field,
            ),
          ),
        );
      });

      test('throws when $field is not a String', () {
        expect(
          () => parser.parse(validPayload(overrides: {field: 42})),
          throwsA(
            isA<PushMessageFormatException>().having(
              (e) => e.field,
              'field',
              field,
            ),
          ),
        );
      });
    }

    test('throws when sentAt is not ISO-8601', () {
      expect(
        () => parser.parse(validPayload(overrides: {'sentAt': 'yesterday'})),
        throwsA(
          isA<PushMessageFormatException>()
              .having((e) => e.field, 'field', 'sentAt')
              .having((e) => e.reason, 'reason', contains('ISO-8601')),
        ),
      );
    });
  });

  group('PushMessage', () {
    test('two messages parsed from the same payload are equal', () {
      expect(parser.parse(validPayload()), parser.parse(validPayload()));
      expect(
        parser.parse(validPayload()).hashCode,
        parser.parse(validPayload()).hashCode,
      );
    });

    test('differing ids are not equal', () {
      expect(
        parser.parse(validPayload()),
        isNot(parser.parse(validPayload(overrides: {'id': 'msg-2'}))),
      );
    });

    test('toString names the message without dumping the body', () {
      expect(parser.parse(validPayload()).toString(), contains('msg-1'));
    });
  });

  group('optional headline fields', () {
    test(
      'accepts a payload with no title or body, as a data-only push has',
      () {
        final message = parser.parse({
          'id': 'msg-1',
          'sentAt': '2026-08-06T09:30:00Z',
          'event': 'sync',
        });

        expect(message.title, isEmpty);
        expect(message.body, isEmpty);
        expect(message.data, {'event': 'sync'});
      },
    );

    test('accepts a blank title, rather than calling it malformed', () {
      final message = parser.parse(validPayload(overrides: {'title': ''}));

      expect(message.title, isEmpty);
    });

    test('still rejects a title of the wrong type', () {
      expect(
        () => parser.parse(validPayload(overrides: {'title': 7})),
        throwsA(isA<PushMessageFormatException>()),
      );
    });

    test('still rejects a body of the wrong type', () {
      expect(
        () => parser.parse(validPayload(overrides: {'body': 7})),
        throwsA(isA<PushMessageFormatException>()),
      );
    });

    test('still requires an id, which is what de-duplicates deliveries', () {
      expect(
        () => parser.parse(validPayload(overrides: {'id': ''})),
        throwsA(isA<PushMessageFormatException>()),
      );
    });

    test(
      'still requires a parseable sentAt, which is what orders the inbox',
      () {
        expect(
          () => parser.parse(validPayload(overrides: {'sentAt': 'yesterday'})),
          throwsA(isA<PushMessageFormatException>()),
        );
      },
    );
  });

  group('trace_id, which is plumbing rather than payload', () {
    test('keeps trace_id out of the data map', () {
      final message = parser.parse({
        'id': 'msg-1',
        'sentAt': '2026-08-13T09:30:00Z',
        'trace_id': 'tr-1',
        'event': 'sync',
      });

      // Whole-map equality, not `containsKey('trace_id')`: this also fails if the
      // copy loop drops the one key it was supposed to keep.
      expect(message.data, {'event': 'sync'});
    });

    test('parses a push with no trace_id at all, and invents none', () {
      // A curl send by hand carries none. The parsed result is asserted rather than
      // `returnsNormally`, which passes for a parser that fabricates a trace id.
      final message = parser.parse({
        'id': 'msg-1',
        'sentAt': '2026-08-13T09:30:00Z',
      });

      expect(message.id, 'msg-1');
      expect(message.data, isEmpty);
    });

    test('keeps scenario_id out of the data map too, and optional', () {
      // Plumbing, like trace_id, so not an "extra data" row — and not required,
      // because a payload composed by hand belongs to no scenario.
      final named = parser.parse({
        'id': 'msg-1',
        'sentAt': '2026-08-13T09:30:00Z',
        'scenario_id': 'c1_priority_high',
        'event': 'sync',
      });

      expect(named.data, {'event': 'sync'});
      expect(PushMessageParser.reservedKeys, contains('scenario_id'));
      expect(PushMessageParser.requiredKeys, isNot(contains('scenario_id')));
    });

    test('is reserved but not required', () {
      // Pinned on the sets directly: adding `trace_id` to `requiredKeys` *and* to the
      // parser leaves every loop above green and breaks only pushes sent by hand.
      expect(PushMessageParser.reservedKeys, contains('trace_id'));
      expect(PushMessageParser.requiredKeys, isNot(contains('trace_id')));
    });
  });

  group('tag, the real android.notification.tag field', () {
    test('reads the tag and keeps it out of the data rows', () {
      final message = parser.parse(
        validPayload(overrides: {'tag': 'build-128'}),
      );

      expect(message.tag, 'build-128');
      expect(
        message.data,
        isEmpty,
        reason:
            'the tag is plumbing the app reads, not something the sender typed '
            'into data — showing it as an extra row would present our own '
            'detail as the sender\'s',
      );
    });

    test('leaves the tag null when the payload carries none', () {
      expect(parser.parse(validPayload()).tag, isNull);
    });

    test('treats a blank tag as none', () {
      final message = parser.parse(validPayload(overrides: {'tag': '  '}));

      expect(
        message.tag,
        isNull,
        reason:
            'a blank tag would key every such notification to the same id and '
            'make unrelated messages replace each other',
      );
    });
  });
}
