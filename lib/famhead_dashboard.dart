import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for formatting date

class FamHeadDashboard extends StatefulWidget {
  const FamHeadDashboard({super.key});

  @override
  FamHeadDashboardState createState() => FamHeadDashboardState();
}

class FamHeadDashboardState extends State<FamHeadDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // Details for each page
  final List<Widget> _pageDetails = [
    const Center(child: Text('Welcome to the Dashboard!')),
    const MyFamilyPage(), // MyFamilyPage integrated here
    const Center(child: Text('Chat with family members.')),
    const Center(child: Text('Consult with a cook here.')),
    const Center(child: Text('Your notifications will appear here.')),
    const BMICalculatorPage(), // BMI Calculator integrated here
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
      _scaffoldKey.currentState
          ?.closeDrawer(); // Close the drawer after selection
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

// My Family Page
class MyFamilyPage extends StatelessWidget {
  const MyFamilyPage({super.key});

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
                  return const AddFamilyMemberDialog();
                },
              );
            },
            child: const Text('Add Family Member'),
          ),
          const SizedBox(height: 20),
          const Text('Here is the list of your family members.'),
        ],
      ),
    );
  }
}

// Add Family Member Dialog
class AddFamilyMemberDialog extends StatefulWidget {
  const AddFamilyMemberDialog({super.key});

  @override
  AddFamilyMemberDialogState createState() => AddFamilyMemberDialogState();
}

class AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  DateTime? _selectedDate;

  // Show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Family Member'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'No Date Selected'
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // Logic to save the family member details goes here

            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// BMI Calculator Page
class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  BMICalculatorPageState createState() => BMICalculatorPageState();
}

class BMICalculatorPageState extends State<BMICalculatorPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  double _bmi = 0.0;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text) / 100;

    setState(() {
      _bmi = weight / (height * height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
              ),
            ),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: const Text('Calculate BMI'),
            ),
            const SizedBox(height: 20),
            Text('Your BMI is: ${_bmi.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
