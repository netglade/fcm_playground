import 'dart:typed_data';

import 'package:fcm_app/domains/notifications/notification_appearance.dart';
import 'package:fcm_app/domains/notifications/notification_images.dart';
import 'package:fcm_app/domains/push/push_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fakes/socket_exception_stub.dart';

PushMessage message(Map<String, String> data) => PushMessage(
  id: 'msg-1',
  title: 'Downloaded locally',
  body: 'Built by the app.',
  sentAt: DateTime.utc(2026, 9, 4, 9),
  data: data,
);

void main() {
  group('loadNotificationImages', () {
    test('fetches nothing for a style that needs no image', () async {
      final requested = <Uri>[];
      final images = await loadNotificationImages(
        message({pushStyleKey: 'inbox', pushLinesKey: 'one|two'}),
        client: MockClient((request) async {
          requested.add(request.url);

          return http.Response('', 200);
        }),
      );

      expect(requested, isEmpty);
      expect(images.picture, isNull);
      expect(images.largeIcon, isNull);
    });

    test('fetches nothing when no style is named at all', () async {
      final requested = <Uri>[];
      await loadNotificationImages(
        message(const {}),
        client: MockClient((request) async {
          requested.add(request.url);

          return http.Response('', 200);
        }),
      );

      expect(requested, isEmpty);
    });

    test('big_picture fetches the image url and nothing else', () async {
      final requested = <Uri>[];
      final images = await loadNotificationImages(
        message({
          pushStyleKey: 'big_picture',
          pushImageUrlKey: 'https://example.test/big.png',
          pushLargeIconUrlKey: 'https://example.test/icon.png',
        }),
        client: MockClient((request) async {
          requested.add(request.url);

          return http.Response.bytes([7, 8, 9], 200);
        }),
      );

      expect(requested.map((uri) => uri.toString()), [
        'https://example.test/big.png',
      ]);
      expect(images.picture, Uint8List.fromList([7, 8, 9]));
      expect(images.largeIcon, isNull);
    });

    test('large_icon fetches the icon url', () async {
      final images = await loadNotificationImages(
        message({
          pushStyleKey: 'large_icon',
          pushLargeIconUrlKey: 'https://example.test/icon.png',
        }),
        client: MockClient((_) async => http.Response.bytes([1], 200)),
      );

      expect(images.largeIcon, Uint8List.fromList([1]));
      expect(images.picture, isNull);
    });

    test(
      'a style asking for an image it never named fetches nothing',
      () async {
        final requested = <Uri>[];
        final images = await loadNotificationImages(
          message({pushStyleKey: 'big_picture'}),
          client: MockClient((request) async {
            requested.add(request.url);

            return http.Response.bytes([1], 200);
          }),
        );

        expect(requested, isEmpty);
        expect(images.picture, isNull);
      },
    );

    // Each of the three below leaves the caller with null, which
    // `appearanceFor` turns into big text — the notification still arrives.
    test('a non-200 yields nothing rather than throwing', () async {
      final images = await loadNotificationImages(
        message({
          pushStyleKey: 'big_picture',
          pushImageUrlKey: 'https://example.test/missing.png',
        }),
        client: MockClient((_) async => http.Response('not found', 404)),
      );

      expect(images.picture, isNull);
    });

    test('a transport failure yields nothing rather than throwing', () async {
      final images = await loadNotificationImages(
        message({
          pushStyleKey: 'big_picture',
          pushImageUrlKey: 'https://example.test/big.png',
        }),
        client: MockClient((_) => throw const SocketExceptionStub()),
      );

      expect(images.picture, isNull);
    });

    // We download this one ourselves, unlike FCM's own `notification.image`,
    // so an oversized body would be held in memory on the draw path.
    test('a body over the cap yields nothing', () async {
      final images = await loadNotificationImages(
        message({
          pushStyleKey: 'big_picture',
          pushImageUrlKey: 'https://example.test/huge.png',
        }),
        client: MockClient(
          (_) async => http.Response.bytes(
            List.filled(maxNotificationImageBytes + 1, 0),
            200,
          ),
        ),
      );

      expect(images.picture, isNull);
    });

    test('a body exactly at the cap is kept', () async {
      final images = await loadNotificationImages(
        message({
          pushStyleKey: 'big_picture',
          pushImageUrlKey: 'https://example.test/big.png',
        }),
        client: MockClient(
          (_) async => http.Response.bytes(
            List.filled(maxNotificationImageBytes, 0),
            200,
          ),
        ),
      );

      expect(images.picture, hasLength(maxNotificationImageBytes));
    });

    test(
      'a url that is not a url yields nothing rather than throwing',
      () async {
        final images = await loadNotificationImages(
          message({
            pushStyleKey: 'big_picture',
            pushImageUrlKey: ':::not a url:::',
          }),
          client: MockClient((_) async => http.Response.bytes([1], 200)),
        );

        expect(images.picture, isNull);
      },
    );
  });
}
