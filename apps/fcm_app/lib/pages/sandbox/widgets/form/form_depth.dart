import 'package:flutter/widgets.dart';

/// How deeply nested the surrounding [FormSection] is, counted from the root.
///
/// The payload nests four levels deep across ten sections, and every section is
/// written without knowing where it sits — `AndroidNotificationSection` appears
/// under `android`, and `FcmOptionsSection` appears under both `message` and
/// `android`. Passing a level down as a constructor argument would mean every
/// section taking a `depth` it only forwards, and one wrong number would style a
/// block as though it lived somewhere it does not.
///
/// So depth is read from the tree instead: each section reads [of] and provides
/// `depth + 1` to whatever it renders inside. A section cannot disagree with its
/// own position, and adding or moving one needs no bookkeeping.
class FormDepth extends InheritedWidget {
  /// Marks [child]'s subtree as sitting at [depth].
  const FormDepth({required this.depth, required super.child, super.key});

  /// Levels between this subtree and the outermost section.
  final int depth;

  /// The depth of the section enclosing [context], or 0 outside any section.
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(FormDepth oldWidget) => oldWidget.depth != depth;
}
