import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_fence/providers/home_provider.dart';
import 'package:geo_fence/providers/summary_provider.dart';
import 'package:geo_fence/providers/tracking_provider.dart';
import 'package:geo_fence/screens/splash_screen.dart';
import 'package:provider/provider.dart';

import 'providers/local_data_provider.dart';
import 'providers/location_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrackingProvider>(create: (_) => TrackingProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
        ChangeNotifierProvider<LocalDataProvider>(create: (_) => LocalDataProvider()),
        ChangeNotifierProvider<LocationProvider>(create: (_) => LocationProvider()),
        ChangeNotifierProvider<SummaryProvider>(create: (_) => SummaryProvider()),
      ],
      child: MaterialApp(
        title: 'Geo Fence',
        navigatorKey: navigatorKey,
        scrollBehavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
        home: SafeArea(child: const SplashScreen()),
      ),
    );
  }
}
