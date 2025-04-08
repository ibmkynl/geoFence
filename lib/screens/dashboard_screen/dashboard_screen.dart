import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_fence/providers/home_provider.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const Dashboard(), fullscreenDialog: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(body: const _ActiveScreen(), bottomNavigationBar: const _BottomNavBar()),
    );
  }
}

class _ActiveScreen extends StatelessWidget {
  const _ActiveScreen();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeProvider, Widget>(
      selector: (_, provider) => provider.selectedScreen,
      builder:
          (_, screen, __) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.fastOutSlowIn,
            child: screen,
          ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeProvider, int>(
      selector: (_, provider) => provider.currentIndex,
      builder:
          (_, index, providerWidget) => BottomNavigationBar(
            currentIndex: index,
            onTap: (newIndex) => context.read<HomeProvider>().switchToIndex(newIndex),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Main'),
              BottomNavigationBarItem(
                icon: Icon(Icons.summarize_outlined),
                activeIcon: Icon(Icons.summarize),
                label: 'Summary',
              ),
            ],
          ),
    );
  }
}
