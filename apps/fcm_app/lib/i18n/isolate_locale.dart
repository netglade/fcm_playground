import 'package:fcm_app/domains/settings/settings.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:flutter/foundation.dart';

/// Points slang at the user's language, read from storage rather than through a
/// widget binding.
///
/// Three callers: `main()`, and the two background isolates, which start cold. All
/// three need the locale set before anything reads channel copy through `t`, or
/// the notifications they draw are the one English thing in a Czech app.
///
/// **Not** `LocaleSettings.useDeviceLocaleSync()` for the no-override case: it
/// resolves through `WidgetsBinding.instance`, which the background isolates never
/// create, so the call throws in debug and null-crashes in release.
/// `PlatformDispatcher.instance` needs no binding, and `AppLocaleUtils.parse`
/// falls back to the base locale rather than returning null.
///
/// The caller must have run `DartPluginRegistrant.ensureInitialized()` first — the
/// store reaches `shared_preferences` through a plugin channel.
///
/// The read is guarded and the fallback still applied on failure. This runs before
/// the work its callers exist to do, so an unguarded throw here would take the
/// whole reply or background draw with it: nothing drawn, nothing stored, not even
/// a log line. No known trigger; it closes a failure *class*.
Future<void> restoreStoredLocale() async {
  AppLocale? storedLocale;
  try {
    storedLocale = await const SharedPreferencesLocaleStore().read();
  } on Object catch (error) {
    debugPrint('Could not read the stored locale: $error');
  }

  LocaleSettings.setLocaleSync(
    storedLocale ??
        AppLocaleUtils.parse(
          PlatformDispatcher.instance.locale.toLanguageTag(),
        ),
  );
}
