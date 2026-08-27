import 'package:fcm_app/pages/sandbox/widgets/form/form_depth.dart';
import 'package:flutter/material.dart';

/// One collapsible object of the payload.
///
/// The payload nests four levels deep across ten sections, so every section starts
/// closed except the outermost. [isValid] drives a badge on the header — without it
/// an invalid field could sit behind a closed section, disabling Send for a reason
/// the user cannot see.
///
/// Depth is shown three ways at once — a coloured rail, a stepped indent, and a
/// header that shrinks as it goes deeper — because indentation alone reads as a
/// flat list once two siblings are open at different depths. Colour answers a
/// different question, open or closed, and the two signals are kept orthogonal.
///
/// The colour is applied here rather than through `ExpansionTile`'s
/// `collapsedTextColor`/`textColor`: the theme bakes a colour into `titleMedium`,
/// and an explicit colour on the `Text` beats the tile's pair, so that route
/// silently does nothing. Hence tracking the open state.
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

  final bool isValid;

  final String? subtitle;

  /// True for the outermost section only: a single closed tile hiding the entire
  /// payload is as unusable as the wall of fields it replaced.
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
