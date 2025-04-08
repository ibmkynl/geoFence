import 'package:flutter/material.dart';
import 'package:geo_fence/models/geo_fence_location.dart';
import 'package:geo_fence/providers/location_provider.dart';
import 'package:geo_fence/providers/tracking_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../providers/local_data_provider.dart';
import '../../../providers/summary_provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocationDialog(context),
        label: const Text("Add Location"),
        icon: const Icon(Icons.add_location_alt),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Selector<TrackingProvider, bool>(
            selector: (_, provider) => provider.isTracking,
            builder:
                (_, isTracking, __) => Text(
                  isTracking ? 'Tracking Active' : 'Not Tracking',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 8),
          const _ClockControls(),
          const Divider(height: 24),
          const Text('Saved Locations', style: TextStyle(fontSize: 16)),
          const Expanded(child: _SavedLocationsList()),
        ],
      ),
    );
  }

  Future<void> _showAddLocationDialog(BuildContext context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final localData = Provider.of<LocalDataProvider>(context, listen: false);
    final location = locationProvider.currentLocation;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not available yet.")));
      return;
    }

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Name this location'),
            content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. Gym, School')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final fence = GeoFenceLocation(
                      name: name,
                      latitude: location.latitude!,
                      longitude: location.longitude!,
                    );
                    await localData.addGeoFence(fence);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class _ClockControls extends StatelessWidget {
  const _ClockControls();

  @override
  Widget build(BuildContext context) {
    return Selector<TrackingProvider, bool>(
      selector: (_, provider) => provider.isTracking,
      builder:
          (_, isTracking, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Clock In'),
                onPressed:
                    isTracking
                        ? null
                        : () async {
                          final started = await context.read<TrackingProvider>().clockIn();
                          if (!started && context.mounted) await _showPermissionDialog(context);
                        },
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Clock Out'),
                onPressed:
                    isTracking
                        ? () async {
                          context.read<TrackingProvider>().clockOut();
                          await context.read<SummaryProvider>().fetchSummaries();
                        }
                        : null,
              ),
            ],
          ),
    );
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Background Permission Needed'),
            content: const Text(
              'To track your location in the background:\n\n'
              '1. Open App Info\n'
              '2. Tap "Permissions"\n'
              '3. Select "Location"\n'
              '4. Choose "Allow all the time"',
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}

class _SavedLocationsList extends StatelessWidget {
  const _SavedLocationsList();

  @override
  Widget build(BuildContext context) {
    return Selector<LocalDataProvider, List<GeoFenceLocation>>(
      selector: (_, provider) => provider.geoFences,
      builder:
          (_, fences, __) =>
              fences.isEmpty
                  ? const Center(child: Text('No saved locations.'))
                  : ListView.builder(
                    itemCount: fences.length,
                    itemBuilder: (context, index) {
                      final item = fences[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('Lat: ${item.latitude}, Lng: ${item.longitude}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => context.read<LocalDataProvider>().deleteGeoFence(item.name),
                        ),
                      );
                    },
                  ),
    );
  }
}
