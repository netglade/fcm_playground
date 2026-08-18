import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The `scenario × device` matrix: how long each send took to arrive.
///
/// A skewed row shows its negative value rather than a clamp. Clamping would turn a
/// measurement error into a false result, and a "1 ms on Xiaomi" would discredit every
/// other number here — which is what `LatencyRow.isSkewed` exists to make visible.
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

    final devices = <String>{for (final row in rows) row.deviceId}.toList();
    final scenarios = <String>{
      for (final row in rows) row.scenarioId ?? 'no scenario',
    }.toList();

    return SingleChildScrollView(
      // Both ways: a matrix grows a column per handset and a row per scenario, and
      // neither axis may push the page's own body sideways.
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
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
                    DataCell(Text(_cellFor(rows, scenario, device))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The milliseconds for one cell, or an em dash where that pair was never measured.
String _cellFor(List<LatencyRow> rows, String scenario, String device) {
  for (final row in rows) {
    if ((row.scenarioId ?? 'no scenario') == scenario &&
        row.deviceId == device) {
      return '${row.latency.inMilliseconds} ms';
    }
  }

  return '—';
}
