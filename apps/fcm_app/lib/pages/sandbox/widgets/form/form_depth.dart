import 'package:flutter/widgets.dart';

/// How deeply nested the surrounding [FormSection] is, counted from the root.
///
/// Read from the tree rather than passed down, because a section does not know
/// where it sits — `FcmOptionsSection` appears under both `message` and `android`.
/// Each section reads [of] and provides `depth + 1` inside, so a section cannot
/// disagree with its own position.
class FormDepth extends InheritedWidget {
  const FormDepth({required this.depth, required super.child, super.key});

  final int depth;

  /// The depth of the section enclosing [context], or 0 outside any section.
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(FormDepth oldWidget) => oldWidget.depth != depth;
}
