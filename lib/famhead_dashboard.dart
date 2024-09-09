import 'package:flutter/material.dart';

class FamHeadDashboard extends StatefulWidget {
  const FamHeadDashboard({super.key});

  @override
  _FamHeadDashboardState createState() => _FamHeadDashboardState();
}

class _FamHeadDashboardState extends State<FamHeadDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // Details for each page
  final List<Widget> _pageDetails = [
    const Center(child: Text('Welcome to the Dashboard!')),
    const Center(child: Text('Here is your family information.')),
    const Center(child: Text('Chat with family members.')),
    const Center(child: Text('Consult with a cooks here.')),
    const Center(child: Text('Your notifications will appear here.')),
    const Center(child: Text('BMI Calculator to help you track your health.')),
    const Center(child: Text('View your transactions here.')),
  ];

  // Titles for the AppBar for each section
  final List<String> _titles = [
    'Dashboard',
    'My Family',
    'Chat',
    'Cook',
    'Notifications',
    'BMI Calculator',
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
              Matrix4.translationValues(_isDrawerOpen ? 200.0 : 0.0, 0.0, 0.0),
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
              // User Profile
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
                      'Mercy Grace Estano',
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
                title: 'My Family',
                isSelected: _selectedIndex == 1,
                onTap: () => _onSelectItem(1),
              ),
              _SidebarMenuItem(
                title: 'Chat',
                isSelected: _selectedIndex == 2,
                onTap: () => _onSelectItem(2),
              ),
              _SidebarMenuItem(
                title: 'Cook',
                isSelected: _selectedIndex == 3,
                onTap: () => _onSelectItem(3),
              ),
              _SidebarMenuItem(
                title: 'Notifications',
                isSelected: _selectedIndex == 4,
                onTap: () => _onSelectItem(4),
              ),
              _SidebarMenuItem(
                title: 'BMI Calculator',
                isSelected: _selectedIndex == 5,
                onTap: () => _onSelectItem(5),
              ),
              _SidebarMenuItem(
                title: 'Transactions',
                isSelected: _selectedIndex == 6,
                onTap: () => _onSelectItem(6),
              ),
              const Spacer(),
              // Logout Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      onDrawerChanged: _onDrawerStateChanged, // Callback to track drawer state
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
