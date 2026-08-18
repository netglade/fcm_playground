import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// Stand-in for a trace with no scenario id, used as both the map key and the
/// label. A real scenario id equal to this would silently merge into the same
/// row, but nothing in the catalogue is named it.
const _noScenario = 'no scenario';

/// The `scenario × device` matrix: how long each send took to arrive.
///
/// `pairLatencies` emits one [LatencyRow] per `(trace, device)`, so several sends
/// of one scenario to one handset land several rows in the same cell. Each cell
/// shows the newest of them by `sentAt` — otherwise a cell measured once would
/// never change again however many times the scenario is re-sent — with the
/// count in parentheses once there is more than one measurement.
///
/// A skewed row shows its negative value rather than a clamp, flagged with
/// [LatencyRow.isSkewed] rather than left silent. Clamping would turn a
/// measurement error into a false result, and a "1 ms on Xiaomi" would discredit
/// every other number here.
class LatencyMatrix extends StatelessWidget {
  const LatencyMatrix({required this.rows, super.key});

  final List<LatencyRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No measurements yet. A row needs both a send and an arrival for the '
            'same trace.',
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final devices = <String>{for (final row in rows) row.deviceId}.toList();
    final scenarios = <String>{
      for (final row in rows) row.scenarioId ?? _noScenario,
    }.toList();
    final grouped = _groupByCell(rows);

    return SingleChildScrollView(
      // Both ways: a matrix grows a column per handset and a row per scenario, and
      // neither axis may push the page's own body sideways.
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('scenario')),
                for (final device in devices) DataColumn(label: Text(device)),
              ],
              rows: [
                for (final scenario in scenarios)
                  DataRow(
                    cells: [
                      DataCell(Text(scenario)),
                      for (final device in devices)
                        _cellFor(theme, grouped, scenario, device),
                    ],
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              '`sent` is when the API received the request, not when FCM '
              'answered, so every figure above includes the time the FCM call '
              'took.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every row, grouped by the `scenario × device` cell it belongs in.
Map<(String, String), List<LatencyRow>> _groupByCell(List<LatencyRow> rows) {
  final grouped = <(String, String), List<LatencyRow>>{};
  for (final row in rows) {
    final key = (row.scenarioId ?? _noScenario, row.deviceId);
    (grouped[key] ??= []).add(row);
  }

  return grouped;
}

/// The cell for `scenario × device`: an em dash where that pair was never
/// measured, otherwise the newest measurement's milliseconds — with the count in
/// parentheses once there is more than one — coloured as an error when
/// [LatencyRow.isSkewed] says the clocks disagree.
DataCell _cellFor(
  ThemeData theme,
  Map<(String, String), List<LatencyRow>> grouped,
  String scenario,
  String device,
) {
  final matches = grouped[(scenario, device)];
  if (matches == null || matches.isEmpty) {
    return const DataCell(Text('—'));
  }

  final newest = matches.reduce((a, b) => a.sentAt.isAfter(b.sentAt) ? a : b);
  final ms = '${newest.latency.inMilliseconds} ms';
  final label = matches.length > 1 ? '$ms (n=${matches.length})' : ms;

  return DataCell(
    Text(
      label,
      style: newest.isSkewed ? TextStyle(color: theme.colorScheme.error) : null,
    ),
  );
}
