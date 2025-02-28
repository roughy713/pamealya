import 'package:flutter/material.dart';
import 'package:pamealya/shared/sidebar_menu_item.dart';
import 'add_admin_page.dart';
import 'dashboard_page.dart';
import 'view_cooks_page.dart';
import 'view_family_heads_page.dart';
import 'approval_page.dart';
import 'my_profile_page.dart';
import 'add_meals_page.dart';
import 'view_meals_page.dart';
import 'admin_notifications_page.dart'; // Import for the notifications page

class AdminDashboard extends StatefulWidget {
  final String firstName;

  const AdminDashboard({super.key, required this.firstName});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    AddAdminPage(),
    AddMealsPage(),
    ViewMealsPage(),
    ViewCooksPage(),
    ViewFamilyHeadsPage(),
    ApprovalPage(),
    AdminNotificationsPage(), // Add the notifications page
    MyProfilePage(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Add Admin',
    'Add Meals',
    'View Meals',
    'View Cooks',
    'View Family Heads',
    'Cooks Approval',
    'Notifications', // Add the notifications title
    'My Profile',
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
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
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectItem;
  final String firstName;

  const NavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectItem,
    required this.firstName,
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
            onTap: () =>
                onSelectItem(8), // Updated from 7 to 8 for profile page
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
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    title: 'Cooks Approval',
                    isSelected: selectedIndex == 6,
                    onTap: () => onSelectItem(6),
                  ),
                  SidebarMenuItem(
                    title: 'Notifications',
                    isSelected: selectedIndex == 7,
                    onTap: () => onSelectItem(7),
                  ),
                  SidebarMenuItem(
                    title: 'My Profile',
                    isSelected: selectedIndex == 8,
                    onTap: () => onSelectItem(8),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login_admin');
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
