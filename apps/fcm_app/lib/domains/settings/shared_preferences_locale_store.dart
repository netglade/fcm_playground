import 'package:fcm_app/domains/settings/locale_store.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The key the override is stored under.
///
/// Public because the background isolate reads the same preference, and tests
/// should name it rather than repeat the literal.
const localeKey = 'locale';

/// Reads and writes the language override, reachable without a widget tree
/// because the background isolate needs it too.
///
/// Deliberately the legacy `SharedPreferences` API, unlike the app's other five
/// stores: they moved to `SharedPreferencesAsync` because its per-isolate cache
/// could miss a concurrent background write, which cannot happen here — a locale
/// is read once at the start of a cold isolate, and [write] uses this same API.
///
/// Do not "modernise" it to match the others. On Android the two APIs are backed
/// by different files, so switching one side would make every stored locale
/// invisible and silently reset the user's language on next launch.
class SharedPreferencesLocaleStore implements LocaleStore {
  const SharedPreferencesLocaleStore();

  /// The stored override, or null when unset — or when the stored tag names a
  /// language this build cannot serve, which a downgrade can leave behind.
  @override
  Future<AppLocale?> read() async {
    final tag = (await SharedPreferences.getInstance()).getString(localeKey);

    if (tag == null) return null;

    // Checked against the generated list, because `AppLocaleUtils.parse` falls
    // back to the base locale rather than returning null — so an unsupported tag
    // must be filtered out here. Reading `supportedLocalesRaw` means adding a
    // locale needs no edit here.
    if (!AppLocaleUtils.supportedLocalesRaw.contains(tag)) return null;

    return AppLocaleUtils.parse(tag);
  }

  /// Records [locale], or clears the preference so a later [read] falls back to
  /// the system. [remove] rather than a sentinel, so [read]'s guard has no
  /// "empty" tag to special-case.
  @override
  Future<void> write(AppLocale? locale) async {
    final preferences = await SharedPreferences.getInstance();

    if (locale == null) {
      await preferences.remove(localeKey);

      return;
    }
    // languageTag, not languageCode: `read` validates against
    // `supportedLocalesRaw`, which slang builds from languageTags. Identical for
    // en and cs, but they diverge once a locale carries a country or script
    // code — and a bare code would then fail its own guard, silently discarding
    // the user's choice.
    await preferences.setString(localeKey, locale.languageTag);
  }
}
