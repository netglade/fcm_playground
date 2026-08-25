import 'package:fcm_app/domains/settings/entities/locale_store.dart';
import 'package:fcm_app/i18n/translations.g.dart';

/// An in-memory [LocaleStore], so a test can start from a chosen language without
/// standing up `SharedPreferences`.
class FakeLocaleStore implements LocaleStore {
  AppLocale? stored;

  @override
  Future<AppLocale?> read() async => stored;

  @override
  Future<void> write(AppLocale? locale) async => stored = locale;
}
