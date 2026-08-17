/// Who this install is, in the `scenario × device` matrix.
///
/// Deliberately not the FCM token. A token rotates on reinstall, on clear-data and
/// whenever Firebase decides to refresh it, so a token-keyed matrix would scatter
/// one handset across several columns.
abstract interface class DeviceIdentity {
  /// This install's identifier, minted on first call and kept from then on.
  Future<String> id();

  /// The human-readable name for this handset, empty until someone sets one.
  Future<String> label();

  Future<void> setLabel(String label);
}
