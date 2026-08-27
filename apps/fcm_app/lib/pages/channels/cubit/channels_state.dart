import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChannelsState {
  const ChannelsState({
    this.isLoading = true,
    this.comparisons = const [],
    this.error,
  });

  final bool isLoading;
  final List<ChannelComparison> comparisons;
  final String? error;
}

/// One channel, as asked for and as the system holds it.
///
/// The page is a comparison rather than a listing, so this pairing — not either
/// side alone — is what the widgets take.
class ChannelComparison {
  const ChannelComparison({required this.requested, required this.actual});

  final AppNotificationChannel requested;

  /// Null when the system has no channel with this id — registration never ran,
  /// or the user deleted it by clearing app data.
  final AndroidNotificationChannel? actual;

  bool get isRegistered => actual != null;

  bool get importanceMatches => actual?.importance == requested.importance;

  /// False whenever Android declined the request, which it does unless the user
  /// has granted notification-policy access. This is h1's whole finding.
  bool get bypassDndMatches => actual?.bypassDnd == requested.bypassDnd;
}
