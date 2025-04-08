import 'package:flutter/material.dart';
import 'package:geo_fence/models/daily_summary.dart';
import 'package:geo_fence/providers/local_data_provider.dart';

class SummaryProvider with ChangeNotifier {
  final LocalDataProvider _localDataProvider = LocalDataProvider();

  List<DailySummary> get summaries => _localDataProvider.allSummaries;

  Future<void> fetchSummaries() async {
    await _localDataProvider.loadAllSummaries();
    notifyListeners();
  }

  Future<void> clearSummaries() async {
    await _localDataProvider.clearAllSummaries();
    notifyListeners();
  }
}
