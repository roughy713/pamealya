import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';
import 'sidebar_menu_item.dart';
import 'meal_plan_dashboard.dart';
import 'my_family_page.dart';
import 'chat_page.dart';
import 'cook_page.dart';
import 'notifications_page.dart';
import 'bmi_calculator_page.dart';
import 'transactions_page.dart';

class FamHeadDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final List<Map<String, dynamic>> mealPlanData;

  const FamHeadDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
    this.mealPlanData = const [],
  }) : super(key: key);

  @override
  FamHeadDashboardState createState() => FamHeadDashboardState();
}

class FamHeadDashboardState extends State<FamHeadDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<String> _titles = [
    'Dashboard',
    'My Family',
    'Chat',
    'Cook',
    'Notifications',
    'BMI Calculator',
    'Transactions',
  ];

  List<Widget> get _pageDetails => [
        widget.mealPlanData.isNotEmpty
            ? MealPlanDashboard(mealPlanData: widget.mealPlanData)
            : const Center(child: Text('Dashboard Content')),
        MyFamilyPage(firstName: widget.firstName, lastName: widget.lastName),
        const ChatPage(),
        const CookPage(),
        const NotificationsPage(),
        const BMICalculatorPage(),
        const TransactionPage(),
      ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _scaffoldKey.currentState?.closeDrawer();
    });
  }

  void _onDrawerStateChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
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
                  color: Colors.black, fontWeight: FontWeight.bold),
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
                      '${widget.firstName} ${widget.lastName}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white),
              SidebarMenuItem(
                title: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () => _onSelectItem(0),
              ),
              SidebarMenuItem(
                title: 'My Family',
                isSelected: _selectedIndex == 1,
                onTap: () => _onSelectItem(1),
              ),
              SidebarMenuItem(
                title: 'Chat',
                isSelected: _selectedIndex == 2,
                onTap: () => _onSelectItem(2),
              ),
              SidebarMenuItem(
                title: 'Cook',
                isSelected: _selectedIndex == 3,
                onTap: () => _onSelectItem(3),
              ),
              SidebarMenuItem(
                title: 'Notifications',
                isSelected: _selectedIndex == 4,
                onTap: () => _onSelectItem(4),
              ),
              SidebarMenuItem(
                title: 'BMI Calculator',
                isSelected: _selectedIndex == 5,
                onTap: () => _onSelectItem(5),
              ),
              SidebarMenuItem(
                title: 'Transactions',
                isSelected: _selectedIndex == 6,
                onTap: () => _onSelectItem(6),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
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
                              Image.asset('assets/logo-dark.png', height: 50),
                              const SizedBox(height: 20),
                              const Text(
                                'Are you sure you want to log out?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _handleLogout(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Logout'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
                  },
                  child:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
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
        child: _pageDetails[_selectedIndex],
      ),
    );
  }
}
