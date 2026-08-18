import 'package:fcm_app/domains/push/entities/push_tap.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_push_source.dart';

void main() {
  late FakePushSource source;

  setUp(() {
    source = FakePushSource();
  });

  tearDown(() async {
    await source.dispose();
  });

  group('the payload stream', () {
    test('buffers a payload emitted before anything listens', () async {
      // The launch message is emitted inside start(), before PushRepository
      // subscribes. A broadcast controller would drop it.
      source.emit({'id': 'launch'});

      final received = <Map<String, Object?>>[];
      source.payloads.listen(received.add);
      await pumpEventQueue();

      expect(received.single['id'], 'launch');
    });
  });

  group('the tap stream', () {
    test('reports a tapped id', () async {
      final tapped = <PushTap>[];
      source.taps.listen(tapped.add);

      source.emitTap('msg-1');
      await pumpEventQueue();

      expect(tapped, [const PushTap('msg-1', OpenedFrom.background)]);
    });

    test('buffers a tap emitted before anything listens', () async {
      source.emitTap('launch');

      final tapped = <PushTap>[];
      source.taps.listen(tapped.add);
      await pumpEventQueue();

      expect(tapped, [const PushTap('launch', OpenedFrom.background)]);
    });
  });
}
