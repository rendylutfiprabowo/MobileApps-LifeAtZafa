import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../pages/home_page.dart';
import '../../pages/absensi_page.dart';
import '../../pages/laporan_page.dart';
import '../../pages/profile_page.dart';
import '../state/auth_state.dart';

class MainLayout extends StatefulWidget {
  final AuthState authState;
  const MainLayout({super.key, required this.authState});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onLogout: widget.authState.logout),
      const AbsensiPage(),
      const LaporanPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade50,
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_15, color: Color(0xFF001F3F)),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Iconsax.clock),
            selectedIcon: Icon(Iconsax.clock5, color: Color(0xFF001F3F)),
            label: "Absensi",
          ),
          NavigationDestination(
            icon: Icon(Iconsax.document),
            selectedIcon: Icon(Iconsax.document5, color: Color(0xFF001F3F)),
            label: "Laporan",
          ),
          NavigationDestination(
            icon: Icon(Iconsax.user),
            selectedIcon: Icon(Iconsax.user5, color: Color(0xFF001F3F)),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
