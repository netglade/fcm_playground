import 'group_a.dart';
import 'group_b.dart';
import 'group_c.dart';
import 'group_d.dart';
import 'scenario.dart';

/// The scenario catalogue, in the order of the source document.
///
/// Eleven groups, each authored in its own file against one table of that
/// document, concatenated here. The name and type are unchanged from the
/// nine-scenario gallery this replaces, so every consumer compiles untouched.
const scenarioGallery = <Scenario>[...groupA, ...groupB, ...groupC, ...groupD];
