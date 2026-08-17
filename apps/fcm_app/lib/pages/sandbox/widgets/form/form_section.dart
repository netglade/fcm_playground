import 'package:flutter/material.dart';

import 'form_depth.dart';

/// One collapsible object of the payload.
///
/// The payload nests four levels deep across ten sections, so every section
/// starts closed except the outermost — otherwise the page is unusable on
/// arrival, which is exactly the defect that moved the gallery to its own page.
///
/// [isValid] drives a badge on the header. Without it an invalid field could sit
/// behind a closed section, disabling Send for a reason the user cannot see.
///
/// **Depth is shown three ways at once**, because one alone is not enough to read
/// four levels of nesting: a coloured rail down the left of the contents, an
/// indent that steps in per level, and a header whose size and weight shrink as it
/// goes deeper. Nesting that is only expressed as indentation reads as a flat list
/// once two siblings are open at different depths — and a payload where the user
/// cannot tell which object a field belongs to is one they will fill in wrongly.
/// The depth itself comes from [FormDepth], read from the tree rather than passed
/// in, so no section can be styled as though it lived somewhere it does not.
///
/// **Colour answers a different question: open or closed.** Size and weight say
/// how deep a section sits; a closed one is dimmed and an open one is at full
/// strength, so finding what is currently expanded does not mean hunting for
/// chevrons down a page of collapsed rows. The two signals are kept orthogonal
/// deliberately — overloading colour with depth as well would make a deep open
/// block and a shallow closed one look alike, which is the confusion this exists
/// to remove.
///
/// The colour is applied here rather than through `ExpansionTile`'s
/// `collapsedTextColor`/`textColor`: the theme bakes a colour into
/// `titleMedium` and friends, and an explicit colour on the `Text` beats the
/// tile's pair, so that route silently does nothing. Hence tracking the open
/// state — it is the only way the header can be made to follow it.
class FormSection extends StatefulWidget {
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
  State<FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final depth = FormDepth.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // The rail brightens with depth so a nested block reads as sitting inside
    // its parent rather than beside it.
    final rail = Color.lerp(
      scheme.outlineVariant,
      scheme.primary,
      (depth * 0.3).clamp(0.0, 0.9),
    )!;

    final base = switch (depth) {
      0 => theme.textTheme.titleMedium,
      1 => theme.textTheme.titleSmall,
      _ => theme.textTheme.bodyMedium,
    };

    return FormDepth(
      depth: depth + 1,
      child: Theme(
        // ExpansionTile draws its own divider lines, which read as extra
        // boundaries between blocks and fight the rail for the eye.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.title,
            style: base?.copyWith(
              fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w600,
              color: _expanded ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
          collapsedIconColor: scheme.onSurfaceVariant,
          iconColor: scheme.onSurface,
          onExpansionChanged: (expanded) =>
              setState(() => _expanded = expanded),
          subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
          trailing: widget.isValid
              ? null
              : Icon(Icons.error_outline, color: scheme.error),
          tilePadding: EdgeInsets.only(left: depth == 0 ? 0 : 8, right: 0),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          initiallyExpanded: widget.initiallyExpanded,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: rail, width: 2)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
