import 'package:flutter/foundation.dart';

import '../domains/settings/data_sources/shared_preferences_locale_store.dart';
import 'translations.g.dart';

/// Points slang at the user's language, read directly from storage rather than
/// through a widget binding.
///
/// Three callers: `main()`, ahead of `configureDependencies()` and the first
/// frame — see the comment at that call site — and the two background isolates,
/// which start cold with no binding of their own. All three need the locale set
/// before anything reads channel copy through `t`; without this the notifications
/// they draw would be the one English thing in a Czech app.
///
/// NOT `LocaleSettings.useDeviceLocaleSync()` for the no-override case, even though
/// `main()` also calls that, later, for its own reason (see the comment there): it
/// resolves through `WidgetsBinding.instance`, and the two background isolates
/// never create a binding — `DartPluginRegistrant.ensureInitialized()` wires plugin
/// channels and nothing else. The call throws in debug and null-crashes in release.
/// `PlatformDispatcher.instance` is a `dart:ui` singleton that needs no binding, and
/// `AppLocaleUtils.parse` falls back to the base locale rather than returning null,
/// which is the behaviour wanted for a tag this build cannot serve.
///
/// The caller must have run `DartPluginRegistrant.ensureInitialized()` first: the
/// store reaches `shared_preferences` through a plugin channel. `main()` gets this
/// for free from `WidgetsFlutterBinding.ensureInitialized()`.
///
/// The read is guarded, and the fallback still applied when it fails. This runs
/// before the work its callers exist to do and outside their own error handling,
/// so an unguarded `SharedPreferences.getInstance()` throwing here would take the
/// whole reply — or the whole background draw — down with it: nothing drawn,
/// nothing stored, not even a log line. There is no known trigger; this closes a
/// failure *class*, not a live bug. A device locale in the wrong language is a far
/// smaller loss than a notification that never appears.
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
