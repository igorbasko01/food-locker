import 'package:flutter/material.dart';
import 'package:food_locker/ui/pages/bite_analytics_page.dart';
import 'package:food_locker/ui/pages/bite_page.dart';
import 'package:food_locker/ui/pages/home_page.dart';
import 'package:food_locker/ui/pages/settings_page.dart';
import 'package:food_locker/ui/pages/weight_page.dart';

/// The shell's four tabs, in bottom-navigation order. Names the single source
/// of truth for that order so tab-specific behaviour (the Bite analytics
/// action, the Bite wake-lock) keys off `AppTab.bite.index` instead of a bare
/// literal that drifts when the order is reshuffled.
enum AppTab { home, weight, bite, settings }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const List<String> _titles = ['Home', 'Weight', 'Bite', 'Settings'];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == AppTab.bite.index)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Bite analytics',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BiteAnalyticsPage()),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          const WeightPage(),
          // The Bite tab keeps the screen awake while logging; tell it whether
          // it is the visible tab so it can release the wake-lock when hidden.
          BitePage(isActive: _currentIndex == AppTab.bite.index),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_outlined),
            activeIcon: Icon(Icons.monitor_weight_rounded),
            label: 'Weight',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant_rounded),
            label: 'Bite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
