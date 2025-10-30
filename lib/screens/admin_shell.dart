import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_calculateTitle(context), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Create Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Manage Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Design Plate',
          ),
        ],
      ),
    );
  }

  static String _calculateTitle(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/create-menu')) {
      return 'Create Menu Item';
    } else if (location.startsWith('/admin/add-staff')) {
      return 'Create User';
    } else if (location.startsWith('/admin/manage-orders')) {
      return 'Manage Orders';
    } else if (location.startsWith('/admin/design-plate')) {
      return 'Design a Plate';
    } else {
      return 'Admin Dashboard';
    }
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/create-menu')) {
      return 1;
    } else if (location.startsWith('/admin/add-staff')) {
      return 2;
    } else if (location.startsWith('/admin/manage-orders')) {
      return 3;
    } else if (location.startsWith('/admin/design-plate')) {
      return 4;
    } else {
      return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/create-menu');
        break;
      case 2:
        context.go('/admin/add-staff');
        break;
      case 3:
        context.go('/admin/manage-orders');
        break;
      case 4:
        context.go('/admin/design-plate');
        break;
    }
  }
}
