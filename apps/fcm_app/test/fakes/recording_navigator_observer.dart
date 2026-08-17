import 'package:flutter/widgets.dart';

/// A [NavigatorObserver] that reports each push as it happens.
///
/// [onPush] is called from inside `Navigator.push`, which is the only moment from
/// which "this was cleared *before* we navigated" is observable — after a settle,
/// both orderings have finished.
class RecordingNavigatorObserver extends NavigatorObserver {
  RecordingNavigatorObserver(this.onPush);

  /// Called with each pushed route, at the instant it is pushed.
  final void Function(Route<dynamic> route) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onPush(route);
  }
}
