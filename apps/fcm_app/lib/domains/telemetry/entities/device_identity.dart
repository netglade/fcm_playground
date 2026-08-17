/// Who this install is, in the `scenario × device` matrix.
///
/// Two values, each with a different owner. The [id] is minted by the app and
/// never changes: it is the matrix column, so one handset must keep one value
/// for as long as the app is installed. The [label] is typed by whoever is
/// holding the handset, and is the only part a human reads.
///
/// Deliberately **not** the FCM token. A token rotates on reinstall, on
/// clear-data and whenever Firebase decides to refresh it — the
/// `b6_token_refresh` scenario exists to force exactly that — so a
/// token-keyed matrix would scatter one handset across several columns and make
/// its latency history unreadable.
abstract interface class DeviceIdentity {
  /// This install's identifier, minted on first call and kept from then on.
  Future<String> id();

  /// The human-readable name for this handset, empty until someone sets one.
  Future<String> label();

  /// Replaces the human-readable name.
  Future<void> setLabel(String label);
}
