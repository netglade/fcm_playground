import 'package:fcm_app/domains/notifications/notification_appearance.dart';
import 'package:fcm_app/domains/push/push_message.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// The bytes the two image styles need, either of them null when there are none.
typedef NotificationImages = ({Uint8List? picture, Uint8List? largeIcon});

/// The most a notification image may weigh before it is dropped.
///
/// FCM downloads `notification.image` itself and answers for its own limits;
/// `big_picture` is downloaded by *this* app, on the path that draws the
/// notification, so an unbounded body would be held in memory there. Two
/// mebibytes is far more than a tray entry can show and far less than a phone
/// will notice.
///
/// Public so a test can sit exactly on the boundary rather than guess at it.
const maxNotificationImageBytes = 2 * 1024 * 1024;

/// How long a single image download may take.
///
/// Short on purpose: the caller is holding up a notification, and a late
/// picture is worth less than a punctual notification without one.
const _timeout = Duration(seconds: 10);

/// Downloads whatever images [message]'s style asks for.
///
/// Fetches nothing at all for the four styles that need no image, so an inbox
/// or a progress notification never touches the network.
///
/// Never throws, and every failure yields null for that image: a non-200, a
/// transport error, a body over [maxNotificationImageBytes], an unparseable
/// url. `appearanceFor` turns a null into big text, so the notification still
/// arrives — just without the picture.
///
/// [client] is injectable because the background isolate has no `getIt` and
/// builds its own, and because a test must not reach the network.
Future<NotificationImages> loadNotificationImages(
  PushMessage message, {
  http.Client? client,
}) async {
  final style = message.data[pushStyleKey];
  final pictureUrl = style == 'big_picture'
      ? message.data[pushImageUrlKey]
      : null;
  final iconUrl = style == 'large_icon'
      ? message.data[pushLargeIconUrlKey]
      : null;
  if (pictureUrl == null && iconUrl == null) {
    return (picture: null, largeIcon: null);
  }

  final own = client ?? http.Client();
  try {
    return (
      picture: await _fetch(own, pictureUrl),
      largeIcon: await _fetch(own, iconUrl),
    );
  } finally {
    // Only a client this function opened: closing one the caller passed in
    // would break the next call through it.
    if (client == null) {
      own.close();
    }
  }
}

/// The bytes at [url], or null when there are none to be had.
Future<Uint8List?> _fetch(http.Client client, String? url) async {
  if (url == null || url.trim().isEmpty) {
    return null;
  }

  try {
    final uri = Uri.parse(url);
    final response = await client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      debugPrint('No image from $url: HTTP ${response.statusCode}');

      return null;
    }
    if (response.bodyBytes.length > maxNotificationImageBytes) {
      debugPrint(
        'No image from $url: ${response.bodyBytes.length} bytes is over the cap',
      );

      return null;
    }

    return response.bodyBytes;
  } on Object catch (error) {
    // Everything: a `FormatException` from a url that is not one, a socket
    // failure, a `TimeoutException`. None of them is worth losing the
    // notification over.
    debugPrint('No image from $url: $error');

    return null;
  }
}
