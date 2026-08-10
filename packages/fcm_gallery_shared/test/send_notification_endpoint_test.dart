import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// Extracted so `test(...)` fits on one line. Inlined, the literal wraps onto
/// a second line and `dart format` keeps the trailing closure hugging the
/// call, which `dcm`'s trailing-comma rule then flags — this sidesteps that
/// clash instead of fighting either tool.
const _kebabRelationDescription =
    'the deployed id is the registered name run through '
    "firebase_functions' kebab-case conversion";

void main() {
  group('SendNotificationEndpoint', () {
    test(_kebabRelationDescription, () {
      final kebab = SendNotificationEndpoint.registeredName.replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '-${match.group(0)!.toLowerCase()}',
      );

      expect(kebab, SendNotificationEndpoint.deployedId);
    });

    test('the registered name is a camelCase Dart identifier', () {
      expect(
        SendNotificationEndpoint.registeredName,
        matches(RegExp(r'^[a-z][a-zA-Z0-9]*$')),
      );
    });
  });
}
