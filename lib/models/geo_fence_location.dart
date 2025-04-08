// lib/models/geo_fence_location.dart
import 'package:hive/hive.dart';

part 'geo_fence_location.g.dart';

@HiveType(typeId: 2)
class GeoFenceLocation extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  GeoFenceLocation({required this.name, required this.latitude, required this.longitude});
}
