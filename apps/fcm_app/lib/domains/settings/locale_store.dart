import 'package:fcm_app/i18n/i18n.dart';

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
  /// The stored override, or null when none was ever chosen — or when the stored tag
  /// names a language this build cannot serve, which a downgrade can leave behind.
  Future<AppLocale?> read();

  /// Records [locale], or clears the override when it is null.
  Future<void> write(AppLocale? locale);
}
