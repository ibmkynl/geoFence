import 'package:hive/hive.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 1)
class DailySummary extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  Map<String, int> locationDurations; // in seconds

  @HiveField(2)
  Map<String, double> locationDistances; // meters per location

  DailySummary({
    required this.date,
    required Map<String, int> locationDurations,
    Map<String, double>? locationDistances,
  }) : locationDurations = Map<String, int>.from(locationDurations),
       locationDistances = Map<String, double>.from(locationDistances ?? {});

  void addDistance(String location, double distanceMeters) {
    locationDistances[location] = (locationDistances[location] ?? 0.0) + distanceMeters;
  }

  Duration getDuration(String locationName) {
    final seconds = locationDurations[locationName] ?? 0;
    return Duration(seconds: seconds);
  }

  void addDuration(String locationName, Duration duration) {
    locationDurations[locationName] = (locationDurations[locationName] ?? 0) + duration.inSeconds;
  }
}
