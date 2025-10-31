// lib/widgets/main_navigator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../screens/admin_panel_screen.dart'; // Import the new Admin screen
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../services/user_state.dart'; // Import UserState

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  // --- MODIFIED: Screens list is now built dynamically ---
  List<Widget> _buildScreens(bool isAdmin) {
    final screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
    // Conditionally add the Admin Panel screen
    if (isAdmin) {
      screens.add(const AdminPanelScreen());
    }
    return screens;
  }

  // --- MODIFIED: Navigation items are now built dynamically ---
  List<BottomNavigationBarItem> _buildNavItems(bool isAdmin) {
     final items = [
        const BottomNavigationBarItem(icon: Icon(Icons.currency_exchange), label: 'Converter'),
        const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
     ];
      // Conditionally add the Admin Panel item
     if (isAdmin) {
        items.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
     }
     return items;
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Access UserState and *listen* for changes ---
    // This makes the admin tab appear/disappear on login/logout
    final userState = Provider.of<UserState>(context);
    final bool isAdmin = userState.isAdmin;

    // Build screens and items based on admin status
    final List<Widget> screens = _buildScreens(isAdmin);
    final List<BottomNavigationBarItem> navItems = _buildNavItems(isAdmin);

    // Ensure selected index is valid if admin logs out while on admin tab
    if (_selectedIndex >= screens.length) {
        _selectedIndex = 0; // Reset to first tab
    }

    return Scaffold(
      // Use IndexedStack to keep screen states alive when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey, // Make unselected items clearer
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensure all labels are shown
      ),
    );
  }
}
