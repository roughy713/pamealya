import 'package:flutter/material.dart';
import 'package:pamealya/home_page.dart';
import 'package:pamealya/shared/sidebar_menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logout Icon in Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF1CBB80),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Logout Title
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Confirmation Text
                const Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Logout Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF1CBB80),
                        minimumSize: const Size(120, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Perform logout
        await Supabase.instance.client.auth.signOut();

        // Redirect to the HomePage and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } catch (e) {
        // Show simple error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                    title: 'Notifications',
                    isSelected: selectedIndex == 4,
                    onTap: () => onItemTap(4),
                  ),
                  SidebarMenuItem(
                    title: 'Reviews',
                    isSelected: selectedIndex == 5,
                    onTap: () => onItemTap(5),
                  ),
                  SidebarMenuItem(
                    title: 'Earnings',
                    isSelected: selectedIndex == 6,
                    onTap: () => onItemTap(6),
                  ),
                  SidebarMenuItem(
                    title: 'Support',
                    isSelected: selectedIndex == 7,
                    onTap: () => onItemTap(7),
                  ),
                ],
              ),
            ),
            // Seamless Logout Button that matches app style
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
              child: InkWell(
                onTap: () => _showLogoutConfirmation(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
