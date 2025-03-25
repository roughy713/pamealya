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
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CBB80).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF1CBB80),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to log out of your account?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1CBB80),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
      // Show modern loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF1CBB80),
              strokeWidth: 3,
            ),
          ),
        ),
      );

      try {
        // Perform logout
        await Supabase.instance.client.auth.signOut();

        // Close loading dialog
        Navigator.of(context).pop();

        // Redirect to the HomePage and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show modern error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Logout failed. Please try again.')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
              title: 'Payment', // Added Payment menu item
              isSelected: selectedIndex == 5,
              onTap: () => onItemTap(5),
            ),
            SidebarMenuItem(
              title: 'Transactions', // Moved below Payment
              isSelected: selectedIndex == 6,
              onTap: () => onItemTap(6),
            ),
            SidebarMenuItem(
              title: 'Support',
              isSelected: selectedIndex == 7,
              onTap: () => onItemTap(7),
            ),
            const Spacer(),
            // Replace the current logout button with this one that blends with your UI
            const Spacer(),
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
