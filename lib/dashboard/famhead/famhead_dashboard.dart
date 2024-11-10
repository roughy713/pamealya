// lib/fam_head_dashboard.dart
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
import 'dart:math';

class FamHeadDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserUsername;

  const FamHeadDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.currentUserUsername,
  }) : super(key: key);

  @override
  FamHeadDashboardState createState() => FamHeadDashboardState();
}

class FamHeadDashboardState extends State<FamHeadDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // State variable to hold the generated meal plan data
  List<List<Map<String, dynamic>>> mealPlanData = [];

  final List<String> _titles = [
    'Dashboard',
    'My Family',
    'Chat',
    'Cook',
    'Notifications',
    'BMI Calculator',
    'Transactions',
  ];

  // Define pages in the navigation
  List<Widget> get _pageDetails => [
        mealPlanData.isNotEmpty
            ? MealPlanDashboard(mealPlanData: mealPlanData)
            : const Center(child: Text('Dashboard Content')),
        MyFamilyPage(
          initialFirstName: widget.firstName,
          initialLastName: widget.lastName,
        ),
        FamHeadChatPage(
          currentUserId: widget.firstName,
          currentUserUsername: widget.currentUserUsername,
        ),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  // Function to generate meal plan
  Future<void> generateMealPlan() async {
    try {
      final response = await Supabase.instance.client
          .from('meal')
          .select()
          .then((data) => data as List<dynamic>);

      if (response.isEmpty) {
        throw 'Error fetching meals or no meals found.';
      }

      List<Map<String, dynamic>> allMeals =
          response.cast<Map<String, dynamic>>();
      List<Map<String, dynamic>> breakfasts = allMeals
          .where((meal) =>
              meal['meal_category_id'] == 1 || meal['meal_category_id'] == '1')
          .toList();
      List<Map<String, dynamic>> lunches = allMeals
          .where((meal) =>
              meal['meal_category_id'] == 2 || meal['meal_category_id'] == '2')
          .toList();
      List<Map<String, dynamic>> dinners = allMeals
          .where((meal) =>
              meal['meal_category_id'] == 3 || meal['meal_category_id'] == '3')
          .toList();

      if (breakfasts.isEmpty || lunches.isEmpty || dinners.isEmpty) {
        throw 'Not enough meals in each category to generate a meal plan.';
      }

      List<List<Map<String, dynamic>>> newMealPlan = List.generate(7, (_) {
        final random = Random();
        return [
          breakfasts[random.nextInt(breakfasts.length)],
          lunches[random.nextInt(lunches.length)],
          dinners[random.nextInt(dinners.length)],
        ];
      });

      // Update the state to reflect the new meal plan
      setState(() {
        mealPlanData = newMealPlan;
        _selectedIndex =
            0; // Navigate to the Dashboard page to view the meal plan
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating meal plan: $e')),
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
        // Only show FloatingActionButton on the "My Family" page (index 1)
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: generateMealPlan,
                label: const Text('Generate Meal Plan'),
                backgroundColor: Colors.yellow,
              )
            : null,
      ),
    );
  }
}
