import 'package:fcm_app/domains/settings/locale_store.dart';
import 'package:fcm_app/i18n/translations.g.dart';

/// An in-memory [LocaleStore], so a test can start from a chosen language without
/// standing up `SharedPreferences`.
class FakeLocaleStore implements LocaleStore {
  AppLocale? stored;

  /// Answers whatever [stored] currently holds, with no persistence to fail or mock.
  @override
  Future<AppLocale?> read() async => stored;

  /// Overwrites [stored], including with null, mirroring the real store clearing its
  /// preference.
  @override
  Future<void> write(AppLocale? locale) async => stored = locale;
}
