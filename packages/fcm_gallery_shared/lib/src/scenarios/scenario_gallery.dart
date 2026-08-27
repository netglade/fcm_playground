import 'package:fcm_gallery_shared/src/scenarios/group_a.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_b.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_c.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_d.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_e.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_f.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_g.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_h.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_i.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_j.dart';
import 'package:fcm_gallery_shared/src/scenarios/group_k.dart';
import 'package:fcm_gallery_shared/src/scenarios/scenario.dart';

/// The scenario catalogue, in the order of the source document: eleven groups, each
/// authored in its own file against one table of that document.
const scenarioGallery = <Scenario>[
  ...groupA,
  ...groupB,
  ...groupC,
  ...groupD,
  ...groupE,
  ...groupF,
  ...groupG,
  ...groupH,
  ...groupI,
  ...groupJ,
  ...groupK,
];
