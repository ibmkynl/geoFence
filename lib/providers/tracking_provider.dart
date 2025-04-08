import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart';

import '../models/location.dart' as model;
import 'local_data_provider.dart';
import 'location_provider.dart';

class TrackingProvider extends ChangeNotifier {
  final Location _location = Location();
  final LocationProvider _locationProvider = LocationProvider();
  final LocalDataProvider _localStorage = LocalDataProvider();

  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _summarySyncTimer;

  bool _tracking = false;

  bool get isTracking => _tracking;

  DateTime? _lastRecordedTime;

  final Map<String, Duration> _durations = {'Home': Duration.zero, 'Office': Duration.zero, 'Traveling': Duration.zero};
  final Map<String, double> _distances = {};

  model.Location? _lastLocation;

  final Map<String, geo.Position> _defaultZones = {
    'Home': geo.Position(
      latitude: 37.7749,
      longitude: -122.4194,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    ),
    'Office': geo.Position(
      latitude: 38.7858,
      longitude: -122.4364,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    ),
  };

  Map<String, Duration> get locationDurations => _durations;

  Future<bool> clockIn() async {
    final permissionGranted = await _locationProvider.requestPermission();
    if (!permissionGranted) return false;

    final serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled && !await _location.requestService()) return false;

    try {
      final backgroundEnabled = await _location.enableBackgroundMode(enable: true);
      if (!backgroundEnabled) return false;
    } catch (_) {
      return false;
    }

    _tracking = true;
    _lastRecordedTime = DateTime.now();
    notifyListeners();

    _location.changeSettings(interval: 60000, distanceFilter: 20); // every 60 seconds or 20 meters
    _locationSubscription = _location.onLocationChanged.listen(_onLocationChanged);
    _startSyncTimer();
    return true;
  }

  void clockOut() {
    _locationSubscription?.cancel();
    _location.enableBackgroundMode(enable: false);
    _tracking = false;
    _summarySyncTimer?.cancel();

    final lastLoc = _localStorage.lastSavedLocation;
    if (lastLoc != null) _processLocation(lastLoc);

    _saveDailySummary();
    notifyListeners();
  }

  void _onLocationChanged(LocationData data) {
    final current = model.Location(
      latitude: data.latitude ?? 0.0,
      longitude: data.longitude ?? 0.0,
      country: '',
      displayName: '',
      lastUpdated: DateTime.now(),
    );

    if (_shouldSaveLocation(current)) {
      _localStorage.updateLastSavedLocation(current);
    }
    _processLocation(current);
  }

  bool _shouldSaveLocation(model.Location current) {
    if (_lastLocation == null) return true;
    final dist = geo.Geolocator.distanceBetween(
      _lastLocation!.latitude!,
      _lastLocation!.longitude!,
      current.latitude!,
      current.longitude!,
    );
    return dist >= 50; // Save only if moved more than 50 meters
  }

  void _processLocation(model.Location current) {
    if (_lastRecordedTime == null) return;

    final now = DateTime.now();
    final delta = now.difference(_lastRecordedTime!);
    _lastRecordedTime = now;

    final insideZones = <String>[];

    _defaultZones.forEach((label, zone) {
      final distance = geo.Geolocator.distanceBetween(
        current.latitude!,
        current.longitude!,
        zone.latitude,
        zone.longitude,
      );
      if (distance <= 50) insideZones.add(label);
    });

    final customZones = _localStorage.geoFences;
    for (final zone in customZones) {
      final distance = geo.Geolocator.distanceBetween(
        current.latitude!,
        current.longitude!,
        zone.latitude,
        zone.longitude,
      );
      if (distance <= 50) {
        insideZones.add(zone.name);
        _durations.putIfAbsent(zone.name, () => Duration.zero);
      }
    }

    if (insideZones.isEmpty) {
      _durations['Traveling'] = _durations['Traveling']! + delta;
      if (_lastLocation != null) {
        final traveled = geo.Geolocator.distanceBetween(
          _lastLocation!.latitude!,
          _lastLocation!.longitude!,
          current.latitude!,
          current.longitude!,
        );
        _distances['Traveling'] = (_distances['Traveling'] ?? 0.0) + traveled;
      }
    } else {
      for (final zone in insideZones) {
        _durations[zone] = _durations[zone]! + delta;
        if (_lastLocation != null) {
          final covered = geo.Geolocator.distanceBetween(
            _lastLocation!.latitude!,
            _lastLocation!.longitude!,
            current.latitude!,
            current.longitude!,
          );
          _distances[zone] = (_distances[zone] ?? 0.0) + covered;
        }
      }
    }

    _lastLocation = current;
    notifyListeners();
  }

  void _startSyncTimer() {
    _summarySyncTimer?.cancel();
    _summarySyncTimer = Timer.periodic(const Duration(minutes: 5), (_) => _saveDailySummary());
  }

  void _saveDailySummary() {
    _localStorage.saveOrUpdateSummary(_durations, _distances);
  }
}
