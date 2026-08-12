import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// The gallery of message-payload templates, grouped by the facet of FCM
/// each one demonstrates.
///
/// One [ExpansionTile] per group keeps all nine templates reachable from a
/// single page; only the first group starts open, so the page is still short
/// on arrival. A scenario is a starting point rather than a fixed payload, so
/// tapping its title applies it to [controller] and the text stays editable
/// afterwards; [onScenarioSelected] fires once that application is done, so
/// this widget owns applying the template and its caller owns whatever
/// happens next — currently, moving to the Sandbox to show it.
class ScenarioGroupList extends StatelessWidget {
  /// Creates the gallery. Tapping a scenario applies it to [controller], then
  /// calls [onScenarioSelected].
  const ScenarioGroupList({
    required this.controller,
    required this.onScenarioSelected,
    super.key,
  });

  /// The controller a tapped scenario is applied to.
  final SandboxController controller;

  /// Called after a tapped scenario has been applied to [controller].
  final VoidCallback onScenarioSelected;

  @override
  Widget build(BuildContext context) {
    final groups = <String>{
      for (final scenario in scenarioGallery) scenario.group,
    };

    return Column(
      children: [
        for (final (index, group) in groups.indexed)
          ExpansionTile(
            title: Text(group),
            initiallyExpanded: index == 0,
            children: [
              for (final scenario in scenarioGallery.where(
                (s) => s.group == group,
              ))
                ListTile(
                  title: Text(scenario.title),
                  onTap: () {
                    controller.applyScenario(scenario);
                    onScenarioSelected();
                  },
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final tag in scenario.tags)
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      Text(scenario.description),
                      if (scenario.expectation case final expectation?)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2, right: 4),
                              child: Icon(
                                Icons.warning_amber_outlined,
                                size: 16,
                              ),
                            ),
                            Expanded(child: Text(expectation)),
                          ],
                        ),
                      if (scenario.requiresKilledApp)
                        const Text('Needs the app killed'),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
