import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart';

import '../models/location.dart' as model;
import 'local_data_provider.dart';
import 'location_provider.dart';

class TrackingProvider extends ChangeNotifier with WidgetsBindingObserver {
  final Location _location = Location();
  final LocationProvider _locationProvider = LocationProvider();
  final LocalDataProvider _localStorage = LocalDataProvider();

  StreamSubscription<LocationData>? _locationStreamSubscription;
  Timer? _summarySyncTimer;

  bool _isTracking = false;

  bool get isTracking => _isTracking;

  DateTime? _lastTimestamp;

  final Map<String, Duration> _locationDurations = {
    'Home': Duration.zero,
    'Office': Duration.zero,
    'Traveling': Duration.zero,
  };
  final Map<String, double> _locationDistances = {};

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

  Map<String, Duration> get locationDurations => _locationDurations;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDailySummary();
    }
  }

  Future<bool> clockIn() async {
    final permissionGranted = await _locationProvider.requestPermission();
    if (!permissionGranted) return false;

    final ready = await _locationProvider.ensureServiceAndBackgroundMode();
    if (!ready) return false;

    _isTracking = true;
    _lastTimestamp = DateTime.now();
    notifyListeners();

    _location.changeSettings(interval: 60000, distanceFilter: 20); // every 60 seconds or 20 meters
    _locationStreamSubscription = _location.onLocationChanged.listen(_onLocationChanged);
    _startSyncTimer();
    return true;
  }

  void clockOut() {
    _locationStreamSubscription?.cancel();
    _location.enableBackgroundMode(enable: false);
    _isTracking = false;
    _summarySyncTimer?.cancel();

    final lastLoc = _localStorage.lastSavedLocation;
    if (lastLoc != null) {
      _updateLastLocationIfMoved(lastLoc);
      _accumulateLocationData(lastLoc);
    }
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

    _updateLastLocationIfMoved(current);
    _accumulateLocationData(current);
  }

  void _updateLastLocationIfMoved(model.Location current) {
    if (_shouldSaveLocation(current)) {
      _localStorage.updateLastSavedLocation(current);
    }
  }

  void _accumulateLocationData(model.Location current) {
    if (_lastTimestamp == null) return;

    final now = DateTime.now();
    final delta = now.difference(_lastTimestamp!);
    _lastTimestamp = now;

    _calculateZoneDurations(current, delta);
    _calculateZoneDistances(current);

    _lastLocation = current;
    notifyListeners();
  }

  void _calculateZoneDurations(model.Location current, Duration delta) {
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
        _locationDurations.putIfAbsent(zone.name, () => Duration.zero);
      }
    }

    if (insideZones.isEmpty) {
      _locationDurations['Traveling'] = _locationDurations['Traveling']! + delta;
    } else {
      for (final zone in insideZones) {
        _locationDurations[zone] = _locationDurations[zone]! + delta;
      }
    }
  }

  void _calculateZoneDistances(model.Location current) {
    if (_lastLocation != null) {
      final traveled = geo.Geolocator.distanceBetween(
        _lastLocation!.latitude!,
        _lastLocation!.longitude!,
        current.latitude!,
        current.longitude!,
      );
      _locationDistances['Traveling'] = (_locationDistances['Traveling'] ?? 0.0) + traveled;
    }
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

  void _startSyncTimer() {
    _summarySyncTimer?.cancel();
    _summarySyncTimer = Timer.periodic(const Duration(minutes: 5), (_) => _saveDailySummary());
  }

  void _saveDailySummary() {
    _localStorage.saveOrUpdateSummary(_locationDurations, _locationDistances);
  }
}
