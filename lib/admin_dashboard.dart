import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'manage_cashier_screen.dart';
import 'manage_menu_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // Daftar halaman konten untuk Admin
  final List<Widget> _pages = [
    const DashboardScreen(),       // Menggantikan placeholder teks (Segera Hadir)
    const ManageCashierScreen(),   
    const ManageMenuScreen(),      
  ];

  void _handleExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Exit'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Exit'),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isMobilePortrait = screenWidth < 700 && !isLandscape;
    final isMobileLandscape = isLandscape && screenHeight < 550;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isMobileLandscape ? 46 : 56,
        title: Text(
          'Admin Back-Office',
          style: TextStyle(fontSize: isMobileLandscape ? 16 : 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.exit_to_app, size: 16),
              label: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _handleExit,
            ),
          ),
        ],
      ),
      // Navigasi Bawah khusus Mobile Portrait (agar konten mendapat 100% lebar layar dan tidak gepeng)
      bottomNavigationBar: isMobilePortrait
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              height: 60,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dasbor',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Akun Kasir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu),
                  selectedIcon: Icon(Icons.restaurant_menu),
                  label: 'Menu & Harga',
                ),
              ],
            )
          : null,
      body: isMobilePortrait
          ? Container(
              color: Colors.grey[50],
              child: _pages[_selectedIndex],
            )
          : Row(
              children: [
                // Sidebar Navigasi Kiri (Ramping di Mode Horizontal Mobile, Lengkap di Tablet/Desktop)
                NavigationRail(
                  minWidth: isMobileLandscape ? 52 : 72,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: isMobileLandscape
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Colors.brown),
                  selectedLabelTextStyle: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelTextStyle: const TextStyle(fontSize: 11),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Tooltip(message: 'Dasbor', child: Icon(Icons.dashboard_outlined)),
                      selectedIcon: Tooltip(message: 'Dasbor', child: Icon(Icons.dashboard)),
                      label: Text('Dasbor'),
                    ),
                    NavigationRailDestination(
                      icon: Tooltip(message: 'Akun Kasir', child: Icon(Icons.people_outline)),
                      selectedIcon: Tooltip(message: 'Akun Kasir', child: Icon(Icons.people)),
                      label: Text('Akun Kasir'),
                    ),
                    NavigationRailDestination(
                      icon: Tooltip(message: 'Menu & Harga', child: Icon(Icons.restaurant_menu)),
                      selectedIcon: Tooltip(message: 'Menu & Harga', child: Icon(Icons.restaurant_menu)),
                      label: Text('Menu & Harga'),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isMobileLandscape ? 8.0 : 20.0),
                        child: IconButton(
                          icon: Icon(Icons.power_settings_new, color: Colors.red[700], size: isMobileLandscape ? 22 : 26),
                          tooltip: 'Keluar (Exit)',
                          onPressed: _handleExit,
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Area Konten Utama
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
    );
  }
}