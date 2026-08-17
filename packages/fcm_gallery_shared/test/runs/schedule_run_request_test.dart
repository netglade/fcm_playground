import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  Map<String, Object?> item({String token = 'device-token'}) => {
    'token': token,
    'message': {
      'notification': {'title': 'Build finished'},
    },
  };

  Map<String, Object?> body({
    Object? delay = 30,
    Object? spacing,
    Object? items,
  }) => {
    'delay_seconds': delay,
    'spacing_seconds': ?spacing,
    'items': items ?? [item()],
  };

  test('reads a delay, a spacing and the items', () {
    final request = ScheduleRunRequest.fromJson(
      body(
        spacing: 5,
        items: [
          item(),
          item(token: 'other'),
        ],
      ),
    );

    expect(request.delaySeconds, 30);
    expect(request.spacingSeconds, 5);
    expect(request.items, hasLength(2));
    expect(request.items.last.target, const TokenTarget('other'));
  });

  test('defaults the spacing to zero, which is what one item wants', () {
    expect(ScheduleRunRequest.fromJson(body()).spacingSeconds, 0);
  });

  test('refuses an empty item list', () {
    expect(
      () => ScheduleRunRequest.fromJson(body(items: <Object?>[])),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('at least one'),
        ),
      ),
    );
  });

  test('refuses more than 100 items', () {
    expect(
      () => ScheduleRunRequest.fromJson(
        body(items: [for (var i = 0; i < 101; i++) item()]),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('100'),
        ),
      ),
    );
  });

  test('refuses a negative delay and one over an hour', () {
    expect(
      () => ScheduleRunRequest.fromJson(body(delay: -1)),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => ScheduleRunRequest.fromJson(body(delay: 3601)),
      throwsA(isA<FormatException>()),
    );
  });

  test('names the offending item, so a bad payload in a batch is findable', () {
    expect(
      () => ScheduleRunRequest.fromJson(
        body(
          items: [
            item(),
            {
              'token': 'device-token',
              'message': {
                'notification': {'titel': 'typo'},
              },
            },
          ],
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('items[1]'), contains('titel')),
        ),
      ),
    );
  });

  test('round-trips, so the app and the server share one spelling', () {
    final original = ScheduleRunRequest.fromJson(body(spacing: 5));

    expect(ScheduleRunRequest.fromJson(original.toJson()).spacingSeconds, 5);
  });
}
