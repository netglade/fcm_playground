import '../../../i18n/translations.g.dart';

/// The language the user picked, or null for "follow the system".
///
/// Null rather than the resolved system locale, so the app keeps following the
/// device after a language change instead of freezing whatever the device happened
/// to be set to on first launch.
///
/// slang's `LocaleSettings` holds the *current* locale and rebuilds the tree when it
/// changes; it does not remember one across launches. That gap is all this exists
/// for.
abstract interface class LocaleStore {
  Future<AppLocale?> read();

  Future<void> write(AppLocale? locale);
}
