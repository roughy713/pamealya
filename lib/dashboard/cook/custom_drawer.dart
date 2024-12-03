import 'package:flutter/material.dart';
import 'package:pamealya/shared/sidebar_menu_item.dart';

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final String userName;
  final VoidCallback onLogoutTap;

  const CustomDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.userName,
    required this.onLogoutTap,
  });

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo-dark.png', height: 50),
              const SizedBox(height: 20),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Logout'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      onLogoutTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1CBB80), // Green color for sidebar background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add logo to the top
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 16.0),
              child: Image.asset(
                'assets/logo-white.png', // Replace with your logo path
                height: 50,
              ),
            ),
            // User Profile Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.green, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white),
            // Navigation Menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SidebarMenuItem(
                    title: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () => onItemTap(0),
                  ),
                  SidebarMenuItem(
                    title: 'Booking Requests',
                    isSelected: selectedIndex == 1,
                    onTap: () => onItemTap(1),
                  ),
                  SidebarMenuItem(
                    title: 'Orders',
                    isSelected: selectedIndex == 2,
                    onTap: () => onItemTap(2),
                  ),
                  SidebarMenuItem(
                    title: 'Chat',
                    isSelected: selectedIndex == 3,
                    onTap: () => onItemTap(3),
                  ),
                  SidebarMenuItem(
                    title: 'Reviews',
                    isSelected: selectedIndex == 4,
                    onTap: () => onItemTap(4),
                  ),
                  SidebarMenuItem(
                    title: 'Earnings',
                    isSelected: selectedIndex == 5,
                    onTap: () => onItemTap(5),
                  ),
                  SidebarMenuItem(
                    title: 'Support',
                    isSelected: selectedIndex == 6,
                    onTap: () => onItemTap(6),
                  ),
                ],
              ),
            ),
            // Logout Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: TextButton(
                onPressed: () => _showLogoutConfirmation(context),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
