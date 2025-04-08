import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/daily_summary.dart';
import '../../../providers/summary_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Summaries'), actions: const [_ClearAllButton()]),
      body: Selector<SummaryProvider, List<DailySummary>>(
        selector: (_, provider) => provider.summaries,
        builder:
            (_, summaries, __) =>
                summaries.isEmpty
                    ? const Center(child: Text('No summary data available.'))
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Duration')),
                          DataColumn(label: Text('Distance')),
                        ],
                        rows: _buildTableRows(summaries),
                      ),
                    ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<SummaryProvider>().fetchSummaries(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  List<DataRow> _buildTableRows(List<DailySummary> summaries) {
    final List<DataRow> rows = [];

    for (final summary in summaries) {
      for (final entry in summary.locationDurations.entries) {
        final distanceMeters = summary.locationDistances[entry.key] ?? 0.0;
        final km = (distanceMeters / 1000).toStringAsFixed(2);
        final duration = Duration(seconds: entry.value);
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(summary.date)),
              DataCell(Text(entry.key)),
              DataCell(Text(_formatDuration(duration))),
              DataCell(Text("$km km")),
            ],
          ),
        );
      }
    }

    return rows;
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return '${h}h ${m}m ${s}s';
  }
}

class _ClearAllButton extends StatelessWidget {
  const _ClearAllButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_forever),
      tooltip: 'Clear All',
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Clear All Summaries?'),
                content: const Text('This will permanently delete all saved summaries.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                ],
              ),
        );

        if (confirmed == true && context.mounted) {
          await context.read<SummaryProvider>().clearSummaries();
        }
      },
    );
  }
}
