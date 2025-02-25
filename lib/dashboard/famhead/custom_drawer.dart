import 'package:flutter/material.dart';
import 'package:pamealya/home_page.dart';
import 'package:pamealya/shared/sidebar_menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTap;
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
      // Perform logout
      await Supabase.instance.client.auth.signOut();

      // Redirect to the HomePage and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1CBB80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/logo-white.png',
                height: 50,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF1CBB80)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white),
            SidebarMenuItem(
              title: 'Dashboard',
              isSelected: selectedIndex == 0,
              onTap: () => onItemTap(0),
            ),
            SidebarMenuItem(
              title: 'My Family',
              isSelected: selectedIndex == 1,
              onTap: () => onItemTap(1),
            ),
            SidebarMenuItem(
              title: 'Chat',
              isSelected: selectedIndex == 2,
              onTap: () => onItemTap(2),
            ),
            SidebarMenuItem(
              title: 'My Bookings',
              isSelected: selectedIndex == 3,
              onTap: () => onItemTap(3),
            ),
            SidebarMenuItem(
              title: 'Notifications',
              isSelected: selectedIndex == 4,
              onTap: () => onItemTap(4),
            ),
            SidebarMenuItem(
              title: 'Payment',           // Added Payment menu item
              isSelected: selectedIndex == 5,
              onTap: () => onItemTap(5),
            ),
            SidebarMenuItem(
              title: 'Transactions',      // Moved below Payment
              isSelected: selectedIndex == 6,
              onTap: () => onItemTap(6),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () => _showLogoutConfirmation(context),
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
