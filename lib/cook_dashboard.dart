import 'package:flutter/material.dart';

class CookDashboard extends StatefulWidget {
  const CookDashboard({super.key});

  @override
  CookDashboardState createState() => CookDashboardState();
}

class CookDashboardState extends State<CookDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // Details for each page
  final List<Widget> _pageDetails = [
    const Center(child: Text('Welcome to the Cook Dashboard!')),
    const MenuPlanningPage(),
    const Center(child: Text('Chat with customers or family members.')),
    const Center(child: Text('Your notifications will appear here.')),
    const Center(child: Text('View your transactions here.')),
  ];

  // Titles for the AppBar for each section
  final List<String> _titles = [
    'Dashboard',
    'Menu Planning',
    'Chat',
    'Notifications',
    'Transactions',
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Color(0xFF1CBB80)),
            elevation: 0,
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        child: Container(
          color: const Color(0xFF1CBB80), // Green color for sidebar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add logo to the top of the user profile
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/logo-white.png', // Path to your logo
                  height: 50, // Adjust size accordingly
                ),
              ),
              const Padding(
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
                      'John Doe, Cook',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white),
              // Navigation Menu
              _SidebarMenuItem(
                title: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () => _onSelectItem(0),
              ),
              _SidebarMenuItem(
                title: 'Menu Planning',
                isSelected: _selectedIndex == 1,
                onTap: () => _onSelectItem(1),
              ),
              _SidebarMenuItem(
                title: 'Chat',
                isSelected: _selectedIndex == 2,
                onTap: () => _onSelectItem(2),
              ),
              _SidebarMenuItem(
                title: 'Notifications',
                isSelected: _selectedIndex == 3,
                onTap: () => _onSelectItem(3),
              ),
              _SidebarMenuItem(
                title: 'Transactions',
                isSelected: _selectedIndex == 4,
                onTap: () => _onSelectItem(4),
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
                                        Image.asset(
                                          'assets/logo-dark.png',
                                          height: 50,
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Are you sure you want to log out?',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
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
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Logout'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Close the dialog
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
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
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      onDrawerChanged: _onDrawerStateChanged,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(left: _isDrawerOpen ? 200 : 0),
        child: _pageDetails[
            _selectedIndex], // Update the center with selected details
      ),
    );
  }
}

// Sidebar menu item widget
class _SidebarMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
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

// Menu Planning Page
class MenuPlanningPage extends StatelessWidget {
  const MenuPlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AddDishDialog();
                },
              );
            },
            child: const Text('Add New Dish'),
          ),
          const SizedBox(height: 20),
          const Text('Plan your weekly menu here.'),
        ],
      ),
    );
  }
}

// Add Dish Dialog
class AddDishDialog extends StatefulWidget {
  const AddDishDialog({super.key});

  @override
  AddDishDialogState createState() => AddDishDialogState();
}

class AddDishDialogState extends State<AddDishDialog> {
  final TextEditingController _dishNameController = TextEditingController();

  @override
  void dispose() {
    _dishNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Dish'),
      content: TextField(
        controller: _dishNameController,
        decoration: const InputDecoration(labelText: 'Dish Name'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle adding the dish logic here
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
