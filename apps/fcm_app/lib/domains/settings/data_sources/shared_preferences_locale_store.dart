import 'package:shared_preferences/shared_preferences.dart';

import '../../../i18n/translations.g.dart';
import '../entities/locale_store.dart';

/// The key the override is stored under.
///
/// Public because the background isolate reads the same preference, and a test
/// seeding it should name it rather than repeat the literal.
const localeKey = 'locale';

/// Reads and writes the language override through the same `SharedPreferences` the
/// rest of the app's small state lives in — including the background isolate, which
/// is why this is reachable without a widget tree.
class SharedPreferencesLocaleStore implements LocaleStore {
  const SharedPreferencesLocaleStore();

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

  @override
  Future<void> write(AppLocale? locale) async {
    final preferences = await SharedPreferences.getInstance();

    if (locale == null) {
      await preferences.remove(localeKey);

      return;
    }
    await preferences.setString(localeKey, locale.languageCode);
  }
}
