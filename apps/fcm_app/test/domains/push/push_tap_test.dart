import 'package:fcm_app/domains/push/push_tap.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushTap', () {
    test('two taps of the same message from the same state are equal', () {
      expect(
        const PushTap('m1', OpenedFrom.background),
        const PushTap('m1', OpenedFrom.background),
      );
    });

    test('the state is part of the identity', () {
      // Not pedantry: the same message tapped from the background and from a cold
      // start are two different observations, and a `==` blind to the state would
      // let a test about one pass against the other.
      expect(
        const PushTap('m1', OpenedFrom.background),
        isNot(const PushTap('m1', OpenedFrom.killed)),
      );
    });

    test('the message id is part of the identity', () {
      expect(
        const PushTap('m1', OpenedFrom.foreground),
        isNot(const PushTap('m2', OpenedFrom.foreground)),
      );
    });
  });
}
