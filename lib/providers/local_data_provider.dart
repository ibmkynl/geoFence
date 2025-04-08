import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../models/daily_summary.dart';
import '../models/geo_fence_location.dart';
import '../models/location.dart';

class LocalDataProvider with ChangeNotifier {
  static final LocalDataProvider _instance = LocalDataProvider._internal();
  factory LocalDataProvider() => _instance;
  LocalDataProvider._internal();

  late final Box _localBox;
  late final Box<GeoFenceLocation> _geoFenceBox;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    final dir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DailySummaryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GeoFenceLocationAdapter());

    _localBox = await Hive.openBox('localData');
    _geoFenceBox = await Hive.openBox<GeoFenceLocation>('geoFences');
    _initialized = true;
    notifyListeners();
  }

  Location? get lastSavedLocation {
    if (!_initialized) return null;
    final raw = _localBox.get('lastUpdatedLocation');
    if (raw == null) return null;
    return Location.fromJson(raw);
  }

  void updateLastSavedLocation(Location location) {
    _localBox.put('lastUpdatedLocation', location.toJson());
  }

  List<GeoFenceLocation> get geoFences {
    if (!_initialized) return [];
    return _geoFenceBox.values.toList();
  }

  Future<void> addGeoFence(GeoFenceLocation fence) async {
    await _geoFenceBox.put(fence.name, fence);
    notifyListeners();
  }

  Future<void> deleteGeoFence(String name) async {
    await _geoFenceBox.delete(name);
    notifyListeners();
  }

  Future<void> clearAllGeoFences() async {
    await _geoFenceBox.clear();
    notifyListeners();
  }

  List<DailySummary> _summaries = [];
  List<DailySummary> get allSummaries => _summaries;

  Future<void> loadAllSummaries() async {
    if (!_initialized) return;

    final loaded = <DailySummary>[];
    for (var key in _localBox.keys) {
      final item = _localBox.get(key);
      if (item is DailySummary) loaded.add(item);
    }

    loaded.sort((a, b) => b.date.compareTo(a.date));
    _summaries = loaded;
    notifyListeners();
  }

  Future<void> clearAllSummaries() async {
    final keys = _localBox.keys.where((k) => _localBox.get(k) is DailySummary).toList();
    for (final k in keys) {
      await _localBox.delete(k);
    }
    _summaries.clear();
    notifyListeners();
  }

  void saveOrUpdateSummary(Map<String, Duration> durations, Map<String, double> distances) {
    final key = DateTime.now().toIso8601String().substring(0, 10);
    final existing = _localBox.get(key);

    DailySummary summary =
        existing is DailySummary ? existing : DailySummary(date: key, locationDurations: {}, locationDistances: {});

    durations.forEach(summary.addDuration);
    distances.forEach(summary.addDistance);

    _localBox.put(key, summary);
  }
}
