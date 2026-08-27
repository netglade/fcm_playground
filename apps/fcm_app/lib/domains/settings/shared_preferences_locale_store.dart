import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations.g.dart';
import 'locale_store.dart';

/// The key the override is stored under.
///
/// Public because the background isolate reads the same preference, and a test
/// seeding it should name it rather than repeat the literal.
const localeKey = 'locale';

/// Reads and writes the language override through the same `SharedPreferences` the
/// rest of the app's small state lives in — including the background isolate, which
/// is why this is reachable without a widget tree.
///
/// The legacy `SharedPreferences` API, not `SharedPreferencesAsync` like the app's
/// other five stores: those switched because the legacy API caches per isolate, and
/// a UI-side cache would miss what a background isolate appended concurrently. That
/// hazard does not apply here. A locale read happens once, at the very start of a
/// cold isolate — the reply isolate included — before anything could have written a
/// stale cache, and the one writer, [write], already goes through this same legacy
/// API, so both sides agree on one backend. Do not "modernise" this to
/// `SharedPreferencesAsync` on the strength of the other five: the two APIs are
/// backed by different files on Android, so switching only the read side (or only
/// the write side) would make a previously-written locale invisible and silently
/// reset every user's language on their next launch.
class SharedPreferencesLocaleStore implements LocaleStore {
  const SharedPreferencesLocaleStore();

  /// The stored override, or null when the preference was never set — or when the
  /// stored tag names a language this build cannot serve, which a downgrade can
  /// leave behind.
  @override
  Future<AppLocale?> read() async {
    final tag = (await SharedPreferences.getInstance()).getString(localeKey);

    if (tag == null) return null;

    // Checked against the generated list rather than trusted to `AppLocaleUtils`'s
    // own parsing: `parse` falls back to the base locale for a tag this build has
    // no translations for, it never returns null, so an unsupported tag has to be
    // filtered out here first — that is exactly the downgrade case. Reading
    // `supportedLocalesRaw` instead of naming the locales by hand is what keeps this
    // from needing an edit when a locale is added.
    if (!AppLocaleUtils.supportedLocalesRaw.contains(tag)) return null;

    return AppLocaleUtils.parse(tag);
  }

  /// Records [locale], or clears the preference so a later [read] falls back to the
  /// system — [remove] rather than a sentinel string, so there is no "empty" tag for
  /// [read]'s guard to have to recognise as a special case.
  @override
  Future<void> write(AppLocale? locale) async {
    final preferences = await SharedPreferences.getInstance();

    if (locale == null) {
      await preferences.remove(localeKey);

      return;
    }
    // languageTag, not languageCode: `read` validates against
    // `AppLocaleUtils.supportedLocalesRaw`, which slang builds from each locale's
    // languageTag. The two are identical for en and cs, and diverge the moment a
    // locale carries a country or script code — at which point a bare code would
    // fail its own guard and the user's choice would be silently discarded.
    await preferences.setString(localeKey, locale.languageTag);
  }
}
