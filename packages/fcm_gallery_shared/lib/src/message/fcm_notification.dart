import 'json_object_reader.dart';

/// The notification FCM renders itself when the app is not in the foreground.
///
/// FCM's `Message.notification`, which applies to every platform; the platform
/// blocks override it where they need to.
class FcmNotification {
  /// Creates a notification, leaving unset fields for FCM to fall back on.
  const FcmNotification({this.title, this.body, this.image});

  /// Reads FCM's `Notification` object.
  factory FcmNotification.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'notification'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static FcmNotification read(JsonObjectReader reader) {
    final notification = FcmNotification(
      title: reader.text('title'),
      body: reader.text('body'),
      image: reader.text('image'),
    );
    reader.requireNothingUnclaimed();

    return notification;
  }

  /// The notification's headline.
  final String? title;

  /// The notification's text.
  final String? body;

  /// URL of an image for FCM to download and display — a URL, never bytes.
  final String? image;

  /// Serialises to FCM's `Notification` shape, omitting unset fields.
  Map<String, Object?> toJson() => {
    'title': ?title,
    'body': ?body,
    'image': ?image,
  };

  @override
  bool operator ==(Object other) =>
      other is FcmNotification &&
      title == other.title &&
      body == other.body &&
      image == other.image;

  @override
  int get hashCode => Object.hash(title, body, image);
}
