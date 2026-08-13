import 'package:flutter/material.dart';

/// One collapsible object of the payload.
///
/// The payload nests four levels deep across ten objects, so every section
/// starts closed — otherwise the page is unusable on arrival, which is exactly
/// the defect that moved the gallery to its own page.
///
/// [isValid] drives a badge on the header. Without it an invalid field could sit
/// behind a closed section, disabling Send for a reason the user cannot see.
class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.isValid,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
    super.key,
  });

  /// The FCM object this section edits, in its own words — `android`, `apns`.
  final String title;

  /// Whether every input inside is currently valid.
  final bool isValid;

  /// What this object is for, when the name alone is not obvious.
  final String? subtitle;

  /// Whether this section is already open when the page first builds.
  ///
  /// False for every nested block, so the page is not a wall of fields on
  /// arrival. True for the outermost one only: a single closed tile hiding the
  /// entire payload is just as unusable as the wall it replaced, and it hides the
  /// payload's shape as well, so the root opens and shows its blocks.
  final bool initiallyExpanded;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: isValid
        ? null
        : Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
    childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    initiallyExpanded: initiallyExpanded,
    children: children,
  );
}
