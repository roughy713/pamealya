import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // List of pages to navigate to
  final List<Widget> _pages = const [
    DashboardPage(),
    AddCookPage(),
    ViewCooksPage(),
    ViewFamilyHeadsPage(),
    ApprovalPage(),
    MyProfilePage(), // Added MyProfilePage
  ];

  // List of titles for AppBar
  final List<String> _titles = const [
    'Dashboard',
    'Add Cook',
    'View Cooks',
    'View Family Heads',
    'Approval',
    'My Profile', // Added My Profile
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selecting an item
  }

  void _onDrawerStateChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(_isDrawerOpen ? 300.0 : 0.0, 0.0, 0.0),
          child: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme:
                const IconThemeData(color: Colors.black), // Set icon color
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: NavigationDrawer(
          selectedIndex: _selectedIndex,
          onSelectItem: _onSelectItem,
        ),
      ),
      onDrawerChanged: _onDrawerStateChanged, // Callback to track drawer state
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(left: _isDrawerOpen ? 200 : 0),
        child: _pages[_selectedIndex],
      ),
    );
  }
}

// Drawer widget
class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectItem;

  const NavigationDrawer(
      {super.key, required this.selectedIndex, required this.onSelectItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1CBB80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add logo above profile
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Image(
              image: AssetImage('assets/logo-white.png'),
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () => onSelectItem(5), // Navigate to My Profile page
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF1CBB80)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Admin',
                    style: TextStyle(
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

          // Drawer menu items
          SidebarMenuItem(
            title: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => onSelectItem(0),
          ),
          SidebarMenuItem(
            title: 'Add Cook',
            isSelected: selectedIndex == 1,
            onTap: () => onSelectItem(1),
          ),
          SidebarMenuItem(
            title: 'View Cooks',
            isSelected: selectedIndex == 2,
            onTap: () => onSelectItem(2),
          ),
          SidebarMenuItem(
            title: 'View Family Heads',
            isSelected: selectedIndex == 3,
            onTap: () => onSelectItem(3),
          ),
          SidebarMenuItem(
            title: 'Approval',
            isSelected: selectedIndex == 4,
            onTap: () => onSelectItem(4),
          ),
          const Spacer(),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Center(
                  child: Column(
                    children: [
                      // The Logout button
                      TextButton(
                        onPressed: () {
                          // Show logout confirmation dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Logo
                                    Image.asset(
                                      'assets/logo-dark.png',
                                      height: 50,
                                    ),
                                    const SizedBox(height: 20),
                                    // Confirmation Text
                                    const Text(
                                      'Are you sure you want to log out?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    // Buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                            // Handle the logout action here
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors
                                                .red, // Red color for the Logout button
                                          ),
                                          child: const Text('Logout'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors
                                                .orange, // Orange color for the Cancel button
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      // Padding below the Logout button
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1CBB80) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// Sample page for Dashboard section
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.person, size: 40),
              Icon(Icons.group, size: 40),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('10 Cooks', style: TextStyle(fontSize: 18)),
              Text('10 Family Heads', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class AddCookPage extends StatelessWidget {
  const AddCookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Add a new Cook'));
  }
}

class ViewCooksPage extends StatelessWidget {
  const ViewCooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('View all Cooks'));
  }
}

class ViewFamilyHeadsPage extends StatelessWidget {
  const ViewFamilyHeadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('View all Family Heads'));
  }
}

class ApprovalPage extends StatelessWidget {
  const ApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Approve requests'));
  }
}

// New My Profile Page
class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('My Profile Page'),
    );
  }
}
