import 'package:fcm_gallery_shared/src/message/json_object_reader.dart';

/// The notification FCM renders itself when the app is not in the foreground.
///
/// FCM's `Message.notification`, which applies to every platform; the platform
/// blocks override it where they need to.
class FcmNotification {
  const FcmNotification({this.title, this.body, this.image});

  factory FcmNotification.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'notification'));

  static FcmNotification read(JsonObjectReader reader) {
    final notification = FcmNotification(
      title: reader.text('title'),
      body: reader.text('body'),
      image: reader.text('image'),
    );
    reader.requireNothingUnclaimed();

    return notification;
  }

  final String? title;

  final String? body;

  /// A URL for FCM to download, never bytes.
  final String? image;

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
