import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A notification action the user pressed: which button, and from which app
/// state.
///
/// Stored against the message id rather than passed along with the tap, so the
/// detail page can still say what happened when the message is reopened from the
/// inbox an hour later.
class PressedAction {
  const PressedAction({required this.actionId, required this.from});

  final String actionId;

  final OpenedFrom from;

  Map<String, Object?> toJson() => {
    'actionId': actionId,
    'from': from.wireName,
  };

  /// Reads one stored entry, or null when it is not one this build understands.
  static PressedAction? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }

    final actionId = json['actionId'];
    final from = OpenedFrom.fromWireName(json['from'] as String?);
    if (actionId is! String || actionId.isEmpty || from == null) {
      return null;
    }

    return PressedAction(actionId: actionId, from: from);
  }

  @override
  bool operator ==(Object other) =>
      other is PressedAction &&
      actionId == other.actionId &&
      from == other.from;

  @override
  int get hashCode => Object.hash(actionId, from);

  @override
  String toString() => 'PressedAction($actionId, ${from.wireName})';
}
