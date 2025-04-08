import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as loc;

import '../models/location.dart';
import '../util/notification_helper.dart';

class LocationProvider with ChangeNotifier {
  static final LocationProvider _singleton = LocationProvider._internal();

  factory LocationProvider() => _singleton;

  LocationProvider._internal();

  final loc.Location _location = loc.Location();
  loc.LocationData? _locationData;
  Location? _current;

  bool _permissionGranted = false;

  bool get initialized => _current != null;

  bool get hasPermission => _permissionGranted;

  Location? get currentLocation => _current;

  Future<void> init() async {
    await geocoding.setLocaleIdentifier('en');
    _permissionGranted = await requestPermission();
    if (_permissionGranted) {
      await _updateCurrentLocation();
    }
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    final notifications = NotificationsHelper();
    var permission = await _location.hasPermission();

    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != loc.PermissionStatus.granted) {
        notifications.showError("Location permission was denied.");
        return false;
      }
    } else if (permission != loc.PermissionStatus.granted) {
      notifications.showError("Location permission not granted.");
      return false;
    }

    final serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled && !await _location.requestService()) {
      notifications.showError("Location services must be enabled.");
      return false;
    }

    try {
      final backgroundGranted = await _location.enableBackgroundMode(enable: true);
      if (!backgroundGranted) {
        notifications.showError("Background location permission denied.");
        return false;
      }
    } catch (e) {
      notifications.showError("Error enabling background mode: $e");
      return false;
    }

    return true;
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled && !await _location.requestService()) return;

      _locationData = await _location.getLocation().timeout(const Duration(seconds: 6));
      _current = await _resolveToLocation();
    } catch (e) {
      NotificationsHelper().showError('Location update failed: $e');
    }
  }

  Future<Location?> _resolveToLocation() async {
    if (_locationData == null) return null;

    try {
      final placeMarks = await geocoding.placemarkFromCoordinates(_locationData!.latitude!, _locationData!.longitude!);

      final placeMark = placeMarks.first;

      return Location(
        country: placeMark.country ?? '',
        displayName: placeMark.locality ?? '',
        latitude: _locationData!.latitude!,
        longitude: _locationData!.longitude!,
        lastUpdated: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
