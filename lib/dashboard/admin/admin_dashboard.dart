import 'package:flutter/material.dart';
import 'package:pamealya/login/login_admin.dart';
import 'package:pamealya/shared/sidebar_menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_admin_page.dart';
import 'dashboard_page.dart';
import 'view_cooks_page.dart';
import 'view_family_heads_page.dart';
import 'approval_page.dart';
import 'my_profile_page.dart';
import 'add_meals_page.dart';
import 'view_meals_page.dart';
import 'admin_notifications_page.dart';
import 'view_support_page.dart';

class AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const AddAdminPage();
      case 2:
        return const AddMealsPage();
      case 3:
        return const ViewMealsPage();
      case 4:
        return const ViewCooksPage();
      case 5:
        return const ViewFamilyHeadsPage();
      case 6:
        return const ViewSupportPage(); // Add the support page
      case 7:
        return const ApprovalPage();
      case 8:
        return const AdminNotificationsPage();
      case 9:
        return MyProfilePage(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
        );
      default:
        return const DashboardPage();
    }
  }

  final List<String> _titles = const [
    'Dashboard',
    'Add Admin',
    'Add Meals',
    'View Meals',
    'View Cooks',
    'View Family Heads',
    'Support', // Add the support title
    'Cooks Approval',
    'Notifications',
    'My Profile',
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginAdmin()),
          (route) => false,
        );
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: NavigationDrawer(
          selectedIndex: _selectedIndex,
          onSelectItem: _onSelectItem,
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
          onSignOut: _signOut,
        ),
      ),
      body: _getPage(_selectedIndex),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;

  const AdminDashboard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectItem;
  final String firstName;
  final String lastName;
  final String email;
  final VoidCallback onSignOut;

  const NavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectItem,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1CBB80),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Image(
              image: AssetImage('assets/logo-white.png'),
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () => onSelectItem(9), // Updated index for profile
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF1CBB80)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SidebarMenuItem(
                    title: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () => onSelectItem(0),
                  ),
                  SidebarMenuItem(
                    title: 'Add Admin',
                    isSelected: selectedIndex == 1,
                    onTap: () => onSelectItem(1),
                  ),
                  SidebarMenuItem(
                    title: 'Add Meal',
                    isSelected: selectedIndex == 2,
                    onTap: () => onSelectItem(2),
                  ),
                  SidebarMenuItem(
                    title: 'View Meals',
                    isSelected: selectedIndex == 3,
                    onTap: () => onSelectItem(3),
                  ),
                  SidebarMenuItem(
                    title: 'View Cooks',
                    isSelected: selectedIndex == 4,
                    onTap: () => onSelectItem(4),
                  ),
                  SidebarMenuItem(
                    title: 'View Family Heads',
                    isSelected: selectedIndex == 5,
                    onTap: () => onSelectItem(5),
                  ),
                  SidebarMenuItem(
                    title: 'Support', // Add Support menu item here
                    isSelected: selectedIndex == 6,
                    onTap: () => onSelectItem(6),
                  ),
                  SidebarMenuItem(
                    title: 'Cooks Approval',
                    isSelected: selectedIndex == 7,
                    onTap: () => onSelectItem(7),
                  ),
                  SidebarMenuItem(
                    title: 'Notifications',
                    isSelected: selectedIndex == 8,
                    onTap: () => onSelectItem(8),
                  ),
                  SidebarMenuItem(
                    title: 'My Profile',
                    isSelected: selectedIndex == 9,
                    onTap: () => onSelectItem(9),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: onSignOut,
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
