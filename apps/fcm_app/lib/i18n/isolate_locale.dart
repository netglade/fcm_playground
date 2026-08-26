import 'dart:ui';

import '../domains/settings/data_sources/shared_preferences_locale_store.dart';
import 'translations.g.dart';

/// Points slang at the user's language, in an isolate that never ran `main()`.
///
/// Both background isolates start cold, and the locale store is the only thing
/// that knows the user's choice. Without this the notifications they draw would be
/// the one English thing in a Czech app.
///
/// NOT `LocaleSettings.useDeviceLocaleSync()` for the no-override case, even though
/// that is what `main()` calls: it resolves through `WidgetsBinding.instance`, and
/// these isolates never create a binding — `DartPluginRegistrant.ensureInitialized()`
/// wires plugin channels and nothing else. The call throws in debug and null-crashes
/// in release. `PlatformDispatcher.instance` is a `dart:ui` singleton that needs no
/// binding, and `AppLocaleUtils.parse` falls back to the base locale rather than
/// returning null, which is the behaviour wanted for a tag this build cannot serve.
///
/// The caller must have run `DartPluginRegistrant.ensureInitialized()` first: the
/// store reaches `shared_preferences` through a plugin channel.
Future<void> restoreIsolateLocale() async {
  final storedLocale = await const SharedPreferencesLocaleStore().read();
  LocaleSettings.setLocaleSync(
    storedLocale ??
        AppLocaleUtils.parse(PlatformDispatcher.instance.locale.toLanguageTag()),
  );
}
