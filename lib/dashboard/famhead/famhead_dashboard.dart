import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';
import 'meal_plan_dashboard.dart';
import 'my_family_page.dart';
import 'famhead_chat_page.dart';
import 'cook_page.dart';
import 'notifications_page.dart';
import 'bmi_calculator_page.dart';
import 'transactions_page.dart';
import 'custom_drawer.dart';

class FamHeadDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserUsername; // Add username field for current user
  final List<Map<String, dynamic>> mealPlanData;

  const FamHeadDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.currentUserUsername, // Add currentUserUsername to constructor
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
        MyFamilyPage(
          initialFirstName: widget.firstName,
          initialLastName: widget.lastName,
        ),
        FamHeadChatPage(
          currentUserId: widget.firstName, // This can be the user ID if needed
          currentUserUsername: widget.currentUserUsername, // Pass username here
        ),
        // Pass the first name and last name to CookPage
        CookPage(
          userFirstName: widget.firstName,
          userLastName: widget.lastName,
        ),
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
    return WillPopScope(
      onWillPop: () async {
        if (_isDrawerOpen) {
          setState(() {
            _isDrawerOpen = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(
                _isDrawerOpen ? 300.0 : 0.0, 0.0, 0.0),
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
        drawer: CustomDrawer(
          selectedIndex: _selectedIndex,
          onItemTap: _onSelectItem,
          userName: '${widget.firstName} ${widget.lastName}',
          onLogoutTap: () => _handleLogout(context),
        ),
        onDrawerChanged: _onDrawerStateChanged,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(left: _isDrawerOpen ? 200 : 0),
          child: _pageDetails[_selectedIndex],
        ),
      ),
    );
  }
}
