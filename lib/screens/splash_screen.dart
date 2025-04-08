import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:geo_fence/providers/location_provider.dart';
import 'package:geo_fence/screens/dashboard_screen/dashboard_screen.dart';
import 'package:provider/provider.dart';

import '../providers/local_data_provider.dart';
import '../providers/summary_provider.dart';
import '../util/notification_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const SplashScreen());
  }

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with AfterLayoutMixin<SplashScreen> {
  @override
  void afterFirstLayout(BuildContext context) => _routeUser();

  final LocalDataProvider localDataProvider = LocalDataProvider();
  final LocationProvider locationProvider = LocationProvider();

  Future<void> _routeUser() async {
    try {
      await _initializeAppServices();

      _redirectToMainScreen();
    } catch (e, s) {
      final bool isOffline = e.toString().contains('offline');
      NotificationsHelper().printIfDebugMode('Error initializing app services: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'You are not connected to internet or your network is too slow.'
                  : 'The Geo Fence App is temporarily unavailable. Please try again later.',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _initializeAppServices() async {
    await Future.wait([localDataProvider.init(), locationProvider.init()]);
  }

  void _redirectToMainScreen() {
    Provider.of<SummaryProvider>(context, listen: false).fetchSummaries();
    Navigator.pushReplacement(context, Dashboard.route());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Welcome")));
  }
}
